Create table SourceT
(
ID int Not null,
FirstName varchar(50),
LastName Varchar(50)
)

Insert into SourceT
Values
(1,'Aaron','Smith'),
(2,'Neal','Garisson'),
(3,'Pat','Simons'),
(4,'Stacy','Peters'),
(5,'Nancy','Trump')

Select * from SourceT

Create table TargetT
(
ID int Not null,
FirstName varchar(50),
LastName Varchar(50)
)

Select * from SourceT
Select * from TargetT

merge targett as t
using sourcet as s
on t.id = s.id

when matched -- Condition of UPDATE

then update
set t.id = s.id,
t.firstname = s.firstname,
t.lastname = s.lastname

when not matched by target -- Condition for INSERT

then insert values(s.id,s.firstname,s.lastname)

when not matched by source -- Condition for DELETE

then delete

output $action,deleted.*,inserted.*;

update sourcet
set firstname = 'Steve',
lastname = 'Rogers'
where id = 5

insert into sourcet values(6,'Stella','John')

delete from SourceT
where id = 4

