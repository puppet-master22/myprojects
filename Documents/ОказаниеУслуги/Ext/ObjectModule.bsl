﻿
Процедура ОбработкаПроведения(Отказ, Режим)

	Движения.ОстаткиМатериалов.Записывать = Истина;
	Движения.СтоимостьМатериалов.Записывать = Истина;
	Движения.Продажи.Записывать = Истина;
	
	// Создать менеджер временных таблиц
	МенеджерВТ = Новый МенеджерВременныхТаблиц;
	
	#Область НоменклатураДокумента
	Запрос = Новый Запрос;
	
	// Укажем, какой менеджер временных таблиц использует этот запрос
	Запрос.МенеджерВременныхТаблиц = МенеджерВТ;

	Запрос.Текст = 
		"ВЫБРАТЬ
				|	ОказаниеУслугиПереченьНоменклатуры.Номенклатура КАК Номенклатура,
				|	ОказаниеУслугиПереченьНоменклатуры.Номенклатура.ВидНоменклатуры КАК ВидНоменклатуры,
				|	ОказаниеУслугиПереченьНоменклатуры.НаборСвойств КАК НаборСвойств,
				|	СУММА(ОказаниеУслугиПереченьНоменклатуры.Количество) КАК КоличествоВДокументе,
				|	СУММА(ОказаниеУслугиПереченьНоменклатуры.Сумма) КАК СуммаВДокументе
				|ПОМЕСТИТЬ НоменклатураДокумента
				|ИЗ
				|	Документ.ОказаниеУслуги.ПереченьНоменклатуры КАК ОказаниеУслугиПереченьНоменклатуры
				|ГДЕ
				|	ОказаниеУслугиПереченьНоменклатуры.Ссылка = &Ссылка
				|
				|СГРУППИРОВАТЬ ПО
				|	ОказаниеУслугиПереченьНоменклатуры.Номенклатура,
				|	ОказаниеУслугиПереченьНоменклатуры.Номенклатура.ВидНоменклатуры,
				|	ОказаниеУслугиПереченьНоменклатуры.НаборСвойств";
	
	Запрос.УстановитьПараметр("Ссылка", Ссылка);
	РезультатЗапроса = Запрос.Выполнить();
	#КонецОбласти
	
	#Область ДвиженияДокумента
	Запрос2 = Новый Запрос;
	Запрос2.МенеджерВременныхТаблиц = МенеджерВТ;
	Запрос2.Текст = 
		"ВЫБРАТЬ
				|	НоменклатураДокумента.Номенклатура КАК Номенклатура,
				|	НоменклатураДокумента.ВидНоменклатуры КАК ВидНоменклатуры,
				|	НоменклатураДокумента.НаборСвойств КАК НаборСвойств,
				|	НоменклатураДокумента.КоличествоВДокументе КАК КоличествоВДокументе,
				|	НоменклатураДокумента.СуммаВДокументе КАК СуммаВДокументе,
				|	ЕСТЬNULL(СтоимостьМатериаловОстатки.СтоимостьОстаток, 0) КАК Стоимость,
				|	ЕСТЬNULL(ОстаткиМатериаловОстатки.КоличествоОстаток, 0) КАК Количество
				|ИЗ
				|	НоменклатураДокумента КАК НоменклатураДокумента
				|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.СтоимостьМатериалов.Остатки(
				|				,
				|				Материал В
				|					(ВЫБРАТЬ
				|						НоменклатураДокумента.Номенклатура
				|					ИЗ
				|						НоменклатураДокумента)) КАК СтоимостьМатериаловОстатки
				|		ПО НоменклатураДокумента.Номенклатура = СтоимостьМатериаловОстатки.Материал
				|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ОстаткиМатериалов.Остатки(
				|				,
				|				Материал В
				|					(ВЫБРАТЬ
				|						НоменклатураДокумента.Номенклатура
				|					ИЗ
				|						НоменклатураДокумента)) КАК ОстаткиМатериаловОстатки
				|		ПО НоменклатураДокумента.Номенклатура = ОстаткиМатериаловОстатки.Материал";
	
	// Установим необходимость блокировки данных в регистрах СтоимостьМатериалов и ОстаткиМатериалов
	Движения.СтоимостьМатериалов.БлокироватьДляИзменения = Истина;
	Движения.ОстаткиМатериалов.БлокироватьДляИзменения = Истина;
	
	// Запишем пустые наборы записей, чтобы читать остатки без учета данных в документе
	Движения.СтоимостьМатериалов.Записать();
	Движения.ОстаткиМатериалов.Записать();
	
	РезультатЗапроса = Запрос2.Выполнить();
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
			Если ВыборкаДетальныеЗаписи.Количество = 0 Тогда
				СтоимостьМатериала = 0;
			Иначе
				СтоимостьМатериала = ВыборкаДетальныеЗаписи.Стоимость / ВыборкаДетальныеЗаписи.Количество;
			КонецЕсли;
		
		Если ВыборкаДетальныеЗаписи.ВидНоменклатуры = Перечисления.ВидыНоменклатуры.Материал Тогда
			
			// регистр ОстаткиМатериалов Расход
			Движение = Движения.ОстаткиМатериалов.Добавить();
			Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
			Движение.Период = Дата;
			Движение.Материал = ВыборкаДетальныеЗаписи.Номенклатура;
			Движение.НаборСвойств = ВыборкаДетальныеЗаписи.НаборСвойств;
			Движение.Склад = Склад;
			Движение.Количество = ВыборкаДетальныеЗаписи.КоличествоВДокументе;
			
			// регистр СтоимостьМатериалов Расход
			Движение = Движения.СтоимостьМатериалов.Добавить();
			Движение.ВидДвижения = ВидДвиженияНакопления.Расход;
			Движение.Период = Дата;
			Движение.Материал = ВыборкаДетальныеЗаписи.Номенклатура;
			Движение.Стоимость = ВыборкаДетальныеЗаписи.КоличествоВДокументе * СтоимостьМатериала;
		КонецЕсли;
			
			// Регистр Продажи
			Движение = Движения.Продажи.Добавить();
			Движение.Период = Дата;
			Движение.Номенклатура =ВыборкаДетальныеЗаписи.Номенклатура;
			Движение.Клиент = Клиент;
			Движение.Мастер = Мастер;
			Движение.Количество = ВыборкаДетальныеЗаписи.КоличествоВДокументе;
			Движение.Выручка = ВыборкаДетальныеЗаписи.СуммаВДокументе;
			Движение.Стоимость = СтоимостьМатериала * ВыборкаДетальныеЗаписи.КоличествоВДокументе;
		КонецЦикла;
		
		Движения.Записать();
	#КонецОбласти
	
	#Область КонтрольОстатков
		Если Режим = РежимПроведенияДокумента.Оперативный Тогда
			// Проверить отрицательные остатки
			Запрос3 = Новый Запрос;
			Запрос3.МенеджерВременныхТаблиц = МенеджерВТ;
			Запрос3.Текст = "ВЫБРАТЬ
			                |	ОстаткиМатериаловОстатки.Материал КАК Материал,
							|	ОстаткиМатериаловОстатки.НаборСвойств КАК НаборСвойств,
			                |	ОстаткиМатериаловОстатки.КоличествоОстаток КАК КоличествоОстаток
			                |ИЗ
			                |	РегистрНакопления.ОстаткиМатериалов.Остатки( , Материал, НаборСвойств) В
			                |					(ВЫБРАТЬ
			                |						НоменклатураДокумента.Номенклатура,
							|						НоменклатураДокумента.НаборСвойств
			                |					ИЗ
			                |						НоменклатураДокумента)
			                |				И Склад = &Склад) КАК ОстаткиМатериаловОстатки
			                |ГДЕ
			                |	ОстаткиМатериаловОстатки.КоличествоОстаток < 0"; 
		Запрос3.УстановитьПараметр("Склад", Склад);
		РезультатЗапроса = Запрос3.Выполнить();
		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
		
			Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
				Сообщение = Новый СообщениеПользователю();
				Сообщение.Текст = "Не хватает " + Строка(- ВыборкаДетальныеЗаписи.КоличествоОстаток) + " единиц материала """ + ВыборкаДетальныеЗаписи.Материал + """" + " из набора свойств """ + ВыборкаДетальныеЗаписи
.НаборСвойств + """";
				Сообщение.Сообщить();
				Отказ = Истина;
			КонецЦикла;
		КонецЕсли;
	#КонецОбласти

КонецПроцедуры
