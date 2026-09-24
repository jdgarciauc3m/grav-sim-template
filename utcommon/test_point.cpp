#include "point.hpp"

#include <gtest/gtest.h>

#include <sstream>

TEST(test_point, default_constructor) {
  common::point const p;
  EXPECT_EQ(p.x, 0.0);
  EXPECT_EQ(p.y, 0.0);
}

TEST(test_point, extraction_operator) {
  std::istringstream iss("3.0 4.0");
  common::point p;
  iss >> p;
  EXPECT_EQ(p.x, 3.0);
  EXPECT_EQ(p.y, 4.0);
}

TEST(test_point, formatting) {
  common::point p{3.5, 4.5};
  std::string const expected = "3.5 4.5";
  std::string const actual = std::format("{}", p);
  EXPECT_EQ(actual, expected);
}

