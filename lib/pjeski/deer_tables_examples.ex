defmodule Pjeski.DeerTablesExamples do
  import PjeskiWeb.Gettext

  def list_examples do
    [
      list_item("classroom"),
      list_item("school"),
      list_item("veterinary_clinic"),
      list_item("family"),
    ]
  end

  def show("classroom") do
    {
      gettext("Classroom (for teachers)"),
      gettext("A good example for starting working with a students database. It has students lists, lessons, homeworks to upload and grades"),
      [
        {gettext("Students"), [gettext("Student's name"), gettext("Date of birth")]},
        {gettext("Lesson"), [gettext("Subject")]},
        {gettext("Exams"), [gettext("Subject"), gettext("Grade"), gettext("Description")]},
        {gettext("Grades"), [gettext("Name"), gettext("Grade"), gettext("Description")]}
      ]
    }
  end

  def show("school") do
    {
      gettext("School (for educational institutions)"),
      gettext("More comprehensive example on how school data could be arranged. It consists of teachers, students, classes, lessons, grades, homeworks and exams"),
      [
        {gettext("Teachers"), [gettext("Teacher's name"), gettext("Area of expertise")]},
        {gettext("Classes"), [gettext("Name"), gettext("Year")]},
        {gettext("Students"), [gettext("Student's name"), gettext("Date of birth")]},
        {gettext("Lessons"), [gettext("Subject")]},
        {gettext("Grades"), [gettext("Name"), gettext("Grade"), gettext("Description")]},
        {gettext("Homeworks"), [gettext("Class"), gettext("Deadline"), gettext("Description")]}
      ]
    }
  end

  def show("family") do
    {
      gettext("Family"),
      gettext("You can store your pictures, tickets, agreements with kids and everything you can think of related to your family"),
      [
        {gettext("Pictures"), [gettext("Collection name"), gettext("Event/Trip"), gettext("Place")]},
        {gettext("Tickets"), [gettext("Type of ticket"), gettext("Date"), gettext("Country/place")]},
        {gettext("Agreements with kids"), [gettext("Name of agreement"), gettext("Promise"), gettext("Conditions"), gettext("Deadline")]}
      ]
    }
  end

  def show("veterinary_clinic") do
    {
      gettext("Veterinary clinic"),
      gettext("You can use it as a starter to work with animal patients. Out of the box you get animals, clients, invoices and visits."),
      [
        {gettext("Animals"), [gettext("Name"), gettext("Year of birth")]},
        {gettext("Clients"), [gettext("Name"), gettext("Phone number")]},
        {gettext("Invoices"), [gettext("Invoice number")]},
        {gettext("Visits"), [gettext("Date")]}
      ]
    }
  end

  defp list_item(key), do: {key, show(key)}
end
