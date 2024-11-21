const int pino_luz = A0;

int qntLuz = 0;

void setup() {
  pinMode(pino_luz, INPUT);

  Serial.begin(9600);
}

void loop() {

  qntLuz = analogRead(pino_luz);

  Serial.print("Quantidade de luz: ");
  Serial.println(qntLuz);

  Serial.println("-------------------------------------");

  delay(2000);
}
