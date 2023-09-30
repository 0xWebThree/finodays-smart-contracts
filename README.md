# Cоздание прототипа системы международных расчетов без недостатков фиатных валют и расписок единого эмиссионного центра
Репозиторий со смарт-контрактами.

## Description
Данный проект позволяет решить следующие проблемы:
<pre>
 - Cанкционное давление при проведении международных операций через зарубежные банки
 - Комиссионные издержки валют в процессе международных операций
 - Курсовые потери связанные с конвертацией валют при переводах
 - Необходимость содержать резервы в «мягких валютах», которые также подвержены инфляции
 - Привязанность к доллару, недружественным валютам
 - Обеспечение свободы в международных взаиморасчетах
</pre>

<p> Проект представляет из себя децентрализованную систему, основанную на приватном блокчейне, что позволит сделать расчеты прозрачными для участников и не доступными для третьих лиц. 
Благодаря независимому мониторингу цены биржевых товаров стран-участниц, применению смарт-контрактов и оракулов мы максимально исключаем посредников из цепочки взаиморасчетов, 
  убираем ненужные прослойки, тем самым повышая отказоустойчивость, надежность, полностью исключая возможность внешнего воздействия (например, блокировки переводов). </p>
<pre>
Смарт-контракты обеспечивают децентрализацию, гарантируют выполнение всех обозначенных условий 
  и используются для:
    - перевода средств
    - погашения платежа биржевым товаром
    - клиринга 
    - записи данных в блокчейн
    - пополнение баланса компании
    - продажи биржевого товара компании
    - получение актуальной цены биржевых товаров
    - трекинг кол-ва биржевых товаров, стоимости
</pre>
<p align="center">
<a target="_blank" href="https://docs.google.com/presentation/d/1UVti95rUJGaFLpSH21lf0jEgOCyVy5hu/edit?usp=sharing&ouid=107789248276318824212&rtpof=true&sd=true"><b>ПРЕЗЕНТАЦИЯ</b></a> </p>    
<p align="center">
<a target="_blank" href="https://www.youtube.com/watch?v=KlEst2H45OM"><b>ДЕМО-ВИДЕО</b></a> </p>

<hr> <hr> <hr>
Smart-contracts are developed on Solidity programming language & tested using Hardhat framework.

### Smart contracts Architecture 
<img src="./Architecture.png" id="a"></img>

### Smart contracts Functionality
<img src="./Functionality.png" id="a"></img>

# Instruction
## Generate docs
### With compilation
```bash
npx hardhat docgen
```
### Without compilation
```bash
npx hardhat docgen --no-compile
```

## Software requirements
Checked on:
  Node: 16.16.0
  NPM: 8.11.0

Recommended using WSLv2 with LTS Node & NPM version

## Installation 
```bash
npm install
```

## Compile contracts
```bash
npx hardhat compile
```

## Run deploy/migrations
```bash
npx hardhat run scripts/deploy.js --network <network_name>
```

## Run tests
```bash
npx hardhat test
```

## Verify contracts
```bash
npx hardhat verify --constructor-args scripts/arguments.js --network sepolia {contractAddress}
```

