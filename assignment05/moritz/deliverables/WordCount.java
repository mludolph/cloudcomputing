/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package cloudcomputing2020;

import org.apache.commons.collections.IteratorUtils;
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.functions.FilterFunction;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.utils.MultipleParameterTool;
import org.apache.flink.streaming.api.datastream.DataStream;
import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.streaming.api.functions.windowing.AllWindowFunction;
import org.apache.flink.streaming.api.functions.windowing.WindowFunction;
import org.apache.flink.streaming.api.windowing.windows.Window;
import org.apache.flink.util.Collector;
import org.apache.flink.util.Preconditions;
import org.apache.flink.core.fs.FileSystem.WriteMode;
import org.apache.flink.streaming.api.TimeCharacteristic;
import org.apache.flink.streaming.api.windowing.assigners.EventTimeSessionWindows;
import org.apache.flink.streaming.api.windowing.time.Time;
import org.apache.flink.streaming.api.windowing.windows.TimeWindow;

import java.util.*;

/**
 * Implements the "WordCount" program that computes a simple word occurrence
 * histogram over text files in a streaming fashion.
 *
 * <p>
 * The input is a plain text file with lines separated by newline characters.
 *
 * <p>
 * Usage: <code>WordCount --input &lt;path&gt; --output &lt;path&gt;</code><br>
 * If no parameters are provided, the program is run with default data from
 * {@link WordCountData}.
 *
 * <p>
 * This example shows how to:
 *
 * <ul>
 * <li>write a simple Flink Streaming program,
 * <li>use tuple data types,
 * <li>write and use user-defined functions.
 * </ul>
 */
public class WordCount {

    // *************************************************************************
    // PROGRAM
    // *************************************************************************

    public static void main(String[] args) throws Exception {

        // Checking input parameters
        final MultipleParameterTool params = MultipleParameterTool.fromArgs(args);

        // set up the execution environment
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        // make parameters available in the web interface
        env.getConfig().setGlobalJobParameters(params);
        env.setStreamTimeCharacteristic(TimeCharacteristic.EventTime);

        // get input data
        DataStream<String> text = null;
        // union all the inputs from text files
        for (String input : params.getMultiParameterRequired("input")) {
            if (text == null) {
                text = env.readTextFile(input);
            } else {
                text = text.union(env.readTextFile(input));
            }
        }
        Preconditions.checkNotNull(text, "Input DataStream should not be null.");

        DataStream<Tuple2<String, Integer>> counts = text.flatMap(new Tokenizer())
                .filter(new AlphabetFilter())
                .keyBy(value -> value.f0)
                .sum(1)
                .keyBy(value -> value.f0)
                .window(EventTimeSessionWindows.withGap(Time.seconds(1)))
                .max(1)
                .windowAll(EventTimeSessionWindows.withGap(Time.seconds(1)))
                .apply(new SortAllFunction());

        // emit result
        counts.writeAsCsv(params.getRequired("output"), WriteMode.OVERWRITE, "\n", ",");

        // execute program
        env.execute("Streaming WordCount");
    }

    public static final class AlphabetFilter implements FilterFunction<Tuple2<String, Integer>> {
        @Override
        public boolean filter(Tuple2<String, Integer> value) {
            return value.f0.chars().allMatch(Character::isLetter);
        }
    }

    public static final class SortAllFunction implements AllWindowFunction<Tuple2<String, Integer>, Tuple2<String, Integer>, TimeWindow> {
        @Override
        public void apply(TimeWindow window, Iterable<Tuple2<String, Integer>> values, Collector<Tuple2<String, Integer>> out) {
            ArrayList<Tuple2<String, Integer>> occurrences = new ArrayList<>();
            values.iterator().forEachRemaining(occurrences::add);
            occurrences.sort(Comparator.comparing(o -> -o.f1));
            occurrences.iterator().forEachRemaining(out::collect);
        }
    }

    /**
     * Implements the string tokenizer that splits sentences into words as a
     * user-defined FlatMapFunction. The function takes a line (String) and splits
     * it into multiple pairs in the form of "(word,1)"
     * ({@code Tuple2<String, Integer>}).
     */
    public static final class Tokenizer implements FlatMapFunction<String, Tuple2<String, Integer>> {
        @Override
        public void flatMap(String value, Collector<Tuple2<String, Integer>> out) {
            // normalize and split the line
            String[] tokens = value.toLowerCase().split("\\W+");

            // emit the pairs
            for (String token : tokens) {
                if (token.length() > 0) {
                    out.collect(new Tuple2<>(token, 1));
                }
            }
        }
    }
}