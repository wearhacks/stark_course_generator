# Stark Labs Course Generator

This is the module with which content creators can generate tutorials (or full-blown courses) 
that will be hosted at Stark Labs.

Read The Fine Manual below to learn how to use it!


## Background

A course in Stark Labs consists of a series of **Chapters** which themselves are made up of **Cards**. 

Each chapter is supposed to have a specific learning objective. The cards employ a variety of means to meet those objectives:
* Plain instructions/textual explanations (which have to be kept short otherwise peolpe just get distracted/discouraged).
* Mini-problems in the form of code snippets that students have to fill in - CodeAcademy style!
* Media, such as GIF images showing what an outcome should look like (e.g. a LED blinking on an Arduino).

The course creation happens through a sequence of commands through which the content is being created. The Stark generator is 
essentially a Ruby script which resides at the root of your installation. This root contains a "courses" directory under which you
can create your courses. You can look at the "Blink" course as an example of what your resulting course would look like.

**TL;DR:** Your objective is to create a **Course** which consists of **Chapters** which in turn is made up of **Cards**. 
You do that through a combination of standard Unix and Stark-specific commands.


## Functions

Legend:
**required** parameters are in **bold text** while *optional* parameters are in *italics*.


### Usage (a.k.a. I have no idea what I'm doing)
```shell
$ stark help
```
Like this guide, this will act like a man page.

### Course Generation
#### Courses & Chapters
At the root of your installation there is a "courses" directory under which you can create courses. 
You can do that conventionally by standard Unix commands: a directory under courses represents a course
so:

```shell
$ mkdir Blink
```
is equivalent to creating a course called "Blink".

Similarly, to create chapters, you conventionally do inside a course's directory:
```shell
$ mkdir "1 - Introduction To Arduino Programming"
```

Of course, you can do both steps in one:
```shell
$ mkdir -p "Blink/1 - Introduction To Arduino Programming"
```
##### Restrictions
* The name of the chapter directories has to follow that format (number, dash, then the title) otherwise your course won't pass validation.
* Currently you can have up to 10 chapters.


#### Course Content
If you have a structure in place then from the root of your installation do:

<pre>
$ stark (add | remove) "Blink/1 - Introduction To Arduino Programming/"Connect Your Arduino"
</pre>

This will trigger the creation/deletion of a card. When creating a card, you have to specify what type 
of card you want (Instruction, Code, Media, Question) as well as other details. This will be done in a Q&A fashion
depending on each card's structure.

##### Restrictions
* You can have a maximum of 10 cards per chapter.


#### Editing Content
Simple - once you are done creating the card you can go edit it. Each card is represented by an XML file. As much as
we all hate XML because it's verbose, we can at least validate easily whether the course you have created follows the
structure that every course should follow.

##### Instructions
Simple enough - this is where you illustrate a topic.
You can optionally provide a media file with your instruction card to illustrate something:

```XML
<card title="Connect Your Arduino">
    <instruction>
        Resistor values are determined by looking at the colored bands printed on them.
    </instruction>
    <media src="ResistorColorChart.png"/>
</card>
```

##### Code
You have to supply 3 files:
1. The file that will contain the template the student will be presented with during the exercise.
   You should put insturctions in the comments.
2. The file that contains a solution which can pass the supplied test.
3. The test that validates a student's solution.

```XML
<card title="Make your Arduino blink!">
    <code template="blink_template.ino" solution="blink_solution.ino" test="blink/blink_test.cc" difficulty="easy"/>
</card>
```

##### Media
Use this card type when you just need to provide a picture for demonstration.
We only support image files (for the time being at least).

```XML
<card title="Connection Demonstration">
    <media src="blink/arduino-blink.gif" />
</card>
```

##### Question
The purpose of questions is to check students' understanding. They follow a multiple choice format. 
You have to supply 2-4 answer options.

Note that you have to specify the correct answer as the first one using the specified tag
(FYI this is due to a limitation in XSD 1.0, combined with the fact that we have to check 
the number of supplied answers and the fact that XSD 1.1.-enabled libraries are not common at all).
Do not worry about the order of the answers - we will mangle them so that the correct answer
is not always the first option. 

The specified difficulty can be set to one of "easy", "medium", "hard".
You can optionally supply a media file (e.g. to illustrate what the result should look like).

```XML
<card title="Check your connectivity">
    <question q="Is your LED blinking?" difficulty="easy">
        <correctAnswer>Yes</correctAnswer>
        <answerOption>No</answerOption>
    </question>
    <media src="blink/arduino-blink.gif" />
</card>
```

### List Course Contents
<pre>
stark list <b>course_name</b>
</pre>
Shows the course content within the current course's context (see what you would get above right after starting the course).

### Run Your Tests
You add tests in test files that come with your code cards. The files are generated when you create the card 
For the Arduino platform, those tests are based on Arduino Mock.

<pre>
stark test <b>course_name</b>
</pre>

Runs all the tests for the given course and displays the results.

### Course Validation
<pre>
stark validate <b>course_name</b>
</pre>

Validates the course's structure against the Stark schema - only courses that comply with the given structure
can be pushed to the platform.

### Course Publication
<pre>
stark push <b>course_name</b>
</pre>

Assembles, validates and publishes the course content to a Stark Labs remote repository. 
If there is any mishap during this process (e.g. supplied code does not pass the supplied 
unit tests or validation fails another step), the content will have to be reviewed before 
it is published.


## Summary

Ideally, your workflow would be along these lines:

1. You have a great idea about how people can learn by doing something on an Arduino.
2. You work out the details - how you would explain things, formulate subproblems to be solved to reach a learning objective etc.
3. You do something along those lines:

``` shell
$ cd stark_course_generator
$ mkdir -p "courses/Blink/1 - Introduction To Arduino Programming"
$ stark add "courses/Blink/1 - Introduction To Arduino Programming"/"1 - Instructions"

# add code cards etc.

$ stark validate Blink

# Oh noes! Something was wrong
# (Fixing...)
# Great, finally done. Let's share the magic with everyone!

$ stark push Blink
``` 
Done! Watch out for feedback from the platform notifying you if server-side processing was OK.


## Recommendations

* The examples presented above might look like they need a lot of typing effort but if you have tab completion it should be a breeze.
* It might be worth aliasing the card creation commands to speed up your workflow.
