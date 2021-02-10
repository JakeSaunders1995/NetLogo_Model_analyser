
import fnmatch
import math
import re
import os
from datetime import datetime
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from model import model
from fpdf import FPDF


## TODO: check that the operator and opperand counting is accurate for more than just the first example

def main():
    operators = get_operators()
    partial_operators = get_partial_operators()
    all_models = get_nlogo_files()
    cleansed_models = clean_models(all_models)

    analysed_models = analyse_models(cleansed_models, operators)

    print_results(analysed_models)


def analyse_models(all_models, operators): #Method to get the average statistics of all models

    analysed_models = []

    for model in all_models:

        # Size metrics
        get_sloc(model)

        #setup for halstead
        calc_n_values(model, operators)

        #Halstead metrics
        calc_h_metrics(model)


    return(all_models)




def get_sloc(model):

    model.sloc = len(model.code)

def calc_n_values(model, operators):
#1

    n1 = 0
    N1 = 0
    n2 = 0
    N2 = 0

    found_operators = []
    found_opperands = []

    parenthesesCount = 0
    bracketCount = 0

    for line in model.code:

        parenthesesCount = parenthesesCount + (line.count("("))
        bracketCount  = bracketCount  + (line.count("["))

        if parenthesesCount > 0:
            found_operators.append("(")

        if bracketCount > 0:
            found_operators.append("[")


        line = re.sub("([\"]).*?([\"])", "\g<1>\g<2>", line) # remves all string within "" so they are not seen as operators
        words = line.split(" ")

        for word in words:


            if word.strip('[]') in operators:

                N1 = N1 + 1
                found_operators.append(word.strip('[]').strip('()'))
            else:
                found_opperands.append(word.strip('[]').strip('()'))


    model.n1 = len((set(found_operators)))
    model.N1 = N1 + bracketCount + parenthesesCount



#2

    found_opperands = (list(filter(None, found_opperands)))
    model.n2 = len((set(found_opperands)))
    model.N2 = len(found_opperands)

def calc_h_metrics(model):

    # Halstead Program Length
    #The total number of operator occurrences and the total number of operand occurrences.
    model.h_prog_length = model.N1 + model.N2

    # Halstead Vocabulary
    #The total number of unique operator and unique operand occurrences.
    model.h_vocab_length = model.n1 + model.n2

    # Program Volume
    #Proportional to program size, represents the size, in bits, of space necessary for storing the program

    model.h_prog_vollume = model.h_prog_length* math.log2(model.h_vocab_length)

    # Program Difficulty
    # This parameter shows how difficult to handle the program is.

    model.h_prog_diff = (model.n1/2)*(model.N2/model.n2)

    #Programming Effort
    # Measures the amount of mental activity needed to translate the existing algorithm into implementation in the specified program language.

    model.h_prog_effort = model.h_prog_diff * model.h_prog_vollume

    #Language Level
    # Shows the algorithm implementation program language level.
    # The same algorithm demands additional effort if it is written in a low-level program language.
    # For example, it is easier to program in Pascal than in Assembler.

    model.h_lang_lvl = model.h_prog_vollume / model.h_prog_diff / model.h_prog_diff

    #Intelligence Content
    # Determines the amount of intelligence presented (stated) in the program This parameter provides a measurement of
    # program complexity, independently of the program language in which it was implemented.

    model.h_int_content = model.h_prog_vollume / model.h_prog_diff

    #Programming Time
    # Shows time (in minutes) needed to translate the existing algorithm into implementation in the specified program
    # language.

    model.h_prog_time = model.h_prog_effort / (60*18)

def create_images(analysed_models):

    # get values

    x = []
    sloc_values = []
    prog_length_values = []
    vocab_length_values =[]
    prog_vollume_values = []
    prog_diffic_values = []
    prog_effort_values = []
    lang_level_values = []
    int_content_values = []
    prog_time_values = []



    for model in analysed_models:
        x.append(model.name.strip(".nlogo"))
        sloc_values.append(model.sloc)
        prog_length_values.append(model.h_prog_length)
        vocab_length_values.append(model.h_vocab_length)
        prog_vollume_values.append(model.h_prog_vollume)
        prog_diffic_values.append(model.h_prog_diff)
        prog_effort_values.append(model.h_prog_effort)
        lang_level_values.append(model.h_lang_lvl)
        int_content_values.append(model.h_int_content)
        prog_time_values.append(model.h_prog_time)




    #SLOC
    plt.figure(0)
    plt.bar(x,sloc_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("SLOC")
    plt.title("SLOC")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks( rotation=90)
    plt.savefig("./Results/SLOC.png")



    #prog length
    plt.figure(1)
    plt.bar(x, prog_length_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Program Length")
    plt.title("Halstead Program Length")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/prog_length.png")



    #vocab length

    plt.figure(2)
    plt.bar(x,vocab_length_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Vocabulary Length")
    plt.title("Halstead Vocabulary Length")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/vocab_length.png")

    #prog vollume

    plt.figure(3)
    plt.bar(x, prog_vollume_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Program Volume")
    plt.title("Halstead Vocabulary Volume")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/prog_vollume.png")

    #prog difficulty

    plt.figure(4)
    plt.bar(x, prog_diffic_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Program Difficulty")
    plt.title("Halstead Program Difficulty")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/prog_diffic.png")

    #prog effort

    plt.figure(5)
    plt.bar(x, prog_effort_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Programming Effort")
    plt.title("Halstead Programming Effort")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/prog_effort.png")

    #Language level

    plt.figure(6)
    plt.bar(x, lang_level_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Language Level")
    plt.title("Halstead Language Level")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/lang_level.png")

    #Intelligence Content

    plt.figure(7)
    plt.bar(x, int_content_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Intelligence Content")
    plt.title("Halstead Intelligence Content")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/i_cont.png")

    #Programming Time

    plt.figure(8)
    plt.bar(x, prog_time_values, color='green')
    plt.xlabel("Model")
    plt.ylabel("Programming Time")
    plt.title("Halstead Programming Time")
    plt.gcf().subplots_adjust(bottom=0.25)
    plt.xticks(rotation=90)
    plt.savefig("./Results/p_time.png")

def print_results(analysed_models):

    create_images(analysed_models)

    # create individual results

    output_file = open("./Results/inidivudal_results.txt", 'w')
    output_file.write(
        "------------------------------Analysis results---------------------------------------" + "\n" + "\n")
    output_file.write("############################################################################" + "\n")
    output_file.write("Individual Model Samples: " + "\n")
    output_file.write("############################################################################" + "\n" + "\n")

    for model in analysed_models:
        output_file.write("\t" + "metadata:" + "\n")
        output_file.write("\t" + "\t" + "Name: " + model.name + "\n" + "\n")

        output_file.write("\t" + "Length metrics:" + "\n")
        output_file.write("\t" + "\t" + "Source Lines of Code (SLOC) = " + str(model.sloc) + "\n" + "\n")

        output_file.write("\t" + "Halstead metrics:" + "\n")
        output_file.write("\t" + "\t" + "Halstead Program Length = " + str(model.h_prog_length) + "\n")
        output_file.write("\t" + "\t" + "Halstead Vocabulary Length = " + str(model.h_vocab_length) + "\n")
        output_file.write("\t" + "\t" + "Halstead Program Volume  = " + str(model.h_prog_vollume) + "\n")
        output_file.write("\t" + "\t" + "Halstead Program Difficulty  = " + str(model.h_prog_diff) + "\n")
        output_file.write("\t" + "\t" + "Halstead Programming Effort  = " + str(model.h_prog_effort) + "\n")
        output_file.write("\t" + "\t" + "Halstead Language Level  = " + str(model.h_lang_lvl) + "\n")
        output_file.write("\t" + "\t" + "Halstead Intelligence Content  = " + str(model.h_int_content) + "\n")
        output_file.write("\t" + "\t" + "Halstead Programming Time  = " + str(model.h_prog_time) + "\n" + "\n")

        output_file.write("\t" + "Control Flow metrics:" + "\n")
        output_file.write("\t" + "\t" + "McCabe's Cyclomatic complexity = " + "TBD" + "\n")
        output_file.write("############################################################################" + "\n" + "\n")

    #create PDF with overal image results

    pdf = FPDF()
    pdf.add_page()
    pdf.set_xy(0, 0)
    pdf.set_font('arial', 'B', 30)
    pdf.cell(60)
    pdf.cell(75, 10, "Analysis Results", 0, 2, 'C')
    pdf.cell(-60)
    pdf.set_font('arial', 'B', 20)
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.cell(75, 10, "Full Sample results:", 0, 2, 'C')

    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.set_font('arial', 'B', 15)
    pdf.cell(75, 10, "Size metrics:", 0, 2, 'C')
    pdf.image("./Results/SLOC.png" , x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.cell(75, 10, "Halstead metrics:", 0, 2, 'C')

    pdf.image("./Results/prog_length.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/vocab_length.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/prog_vollume.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/prog_diffic.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/prog_effort.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/lang_level.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/i_cont.png", x=None, y=None, w=200, h=175, type='', link='')
    pdf.cell(75, 10, "", 0, 2, 'C')
    pdf.image("./Results/p_time.png", x=None, y=None, w=200, h=175, type='', link='')



    pdf.output('./Results/Sample_Results.pdf', 'F')







def get_nlogo_files():

    file_names = fnmatch.filter(os.listdir("coMSES_NetLogo_models/"), "*.nlogo")  # get all .nlogo file names

    all_models = []

    for name in file_names:  # reading and creating model objects
        if os.path.isfile("coMSES_NetLogo_models/" + name):
            f = open("coMSES_NetLogo_models/" + name, encoding="utf8")
            m = model(name, f.readlines(), 0, 0, 0,0,0,0,0,0,0,0,0)
            all_models.append(m)

    return all_models

def clean_models(all_models):

    cleansed_models = []

    # removing comments and gui code
    for model in all_models:
        newLines = []
        eof = False
        Lines = model.code
        for line in Lines:
            if "@#$#@#$#@" in line:
                eof = True

            if not eof:

                line = line.split(";")[0]  # Strip all the comments
                line = line.strip() # Strip any space
                if line != '':  # remove empty lines
                    newLines.append(line)






        model.code = newLines

        cleansed_models.append(model)

    return cleansed_models

def get_operators():

    operator_file = open("operators.txt", encoding="utf8")
    raw_operators = operator_file.readlines()
    operators = []


    for line in raw_operators:
        line = line.strip('\n')
        operators.append(line)


    return operators


def get_partial_operators():
    print(" ")

if __name__ == '__main__':

    main()
