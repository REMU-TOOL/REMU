#ifndef __UTILS_HPP__
#define __UTILS_HPP__

#include <cstddef>
#include <filesystem>
#include <fmt/core.h>
#include <fmt/ranges.h>
#include <fstream>
#include <functional>
#include <iostream>
#include <string>
#include <vector>

namespace utils {
template <typename T, typename U>
U foldLeft(const std::vector<T> &data, const U &initialValue,
           const std::function<U(U, T)> &foldFn) {
  typedef typename std::vector<T>::const_iterator Iterator;
  U accumulator = initialValue;
  Iterator end = data.cend();
  for (Iterator it = data.cbegin(); it != end; ++it) {
    accumulator = foldFn(accumulator, *it);
  }
  return accumulator;
}

template <typename T>
T reduce(const std::vector<T> &data, const std::function<T(T, T)> &reduceFn) {
  typedef typename std::vector<T>::const_iterator Iterator;
  Iterator it = data.cbegin();
  Iterator end = data.cend();
  if (it == end) {
    throw 0;
  } else {
    T accumulator = *it;
    ++it;
    for (; it != end; ++it) {
      accumulator = reduceFn(accumulator, *it);
    }
    return accumulator;
  }
}

inline std::vector<size_t> tabulate(size_t begin, size_t end, size_t step = 1) {
  auto ret = std::vector<size_t>();
  for (size_t i = begin; i < end; i = i + step)
    ret.push_back(i);
  return ret;
}

inline std::vector<size_t> tabulate(size_t end, size_t step = 1) {
  auto ret = std::vector<size_t>();
  for (size_t i = 0; i < end; i = i + step)
    ret.push_back(i);
  return ret;
}

template <typename T, typename U>
std::vector<U> map(const std::vector<T> &data,
                   const std::function<U(T)> mapper) {
  std::vector<U> result;
  foldLeft<T, std::vector<U> &>(
      data, result, [mapper](std::vector<U> &res, T value) -> std::vector<U> & {
        res.push_back(mapper(value));
        return res;
      });
  return result;
}

inline std::string mkString(std::vector<std::string> args,
                            std::string delim = "\n", std::string begin = "",
                            std::string end = "", bool reverse = false) {
  if (reverse)
    std::reverse(args.begin(), args.end());
  return fmt::format("{}{}{}", begin, fmt::join(args, delim), end);
}

template <typename T>
std::vector<T> filter(const std::vector<T> &data,
                      std::function<bool(T)> filterFn) {
  std::vector<T> result;
  foldLeft<T, std::vector<T> &>(
      data, result,
      [filterFn](std::vector<T> &res, T value) -> std::vector<T> & {
        if (filterFn(value)) {
          res.push_back(value);
        }
        return res;
      });
  return result;
}

inline size_t intCeil(size_t n, size_t unit) {
  return (((unit - 1) + n) / (unit)) * unit;
}

inline bool writeFile(std::filesystem::path fileName, std::string content) {
  std::ofstream file;
  try {
    file.exceptions(std::ios_base::failbit | std::ios_base::badbit);
    file.open(fileName,
              std::ios_base::out |
                  std::ios_base::trunc); // 'trunc'选项会清空文件内容
    if (!file.is_open()) {
      std::cerr << "Failed to open file." << std::endl;
      return false;
    }

    file << content;

    file.close();
  } catch (const std::exception &e) {
    std::cerr << "Exception caught: " << e.what() << std::endl;
    return false;
  }
  return true;
}

} // namespace utils

#endif // __UTILS_HPP__