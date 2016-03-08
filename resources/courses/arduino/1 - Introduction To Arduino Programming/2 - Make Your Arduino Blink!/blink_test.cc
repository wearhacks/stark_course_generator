 #include "gtest/gtest.h"
 #include "arduino-mock/Arduino.h"
 #include "arduino-mock/Serial.h"
 
 #include "blink_solution.ino"
 
 using ::testing::Return;

 TEST(loop, pushed) {
   ArduinoMock* arduinoMock = arduinoMockInstance();
   EXPECT_CALL(*arduinoMock, digitalWrite(13, HIGH));
   EXPECT_CALL(*arduinoMock, digitalWrite(13, LOW));
   EXPECT_CALL(*arduinoMock, delay(1000)).Times(2);
   loop();
   releaseArduinoMock();
 }