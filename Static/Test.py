from pyspark import SparkContext
sc = SparkContext('local', 'test')
textFile = sc.textFile('hdfs://localhost:9000/word.txt')
wordCount = textFile.flatMap(lambda line: line.split(" ")).map(lambda word: (word,1)).reduceByKey(lambda a, b : a + b)
print(wordCount.collect())
