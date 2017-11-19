#pragma once

#include <functional>
#include <system_error>
#include <utility>

template<typename Expected, typename Callable, typename... Args>
void checked_invoke(const Expected expected, Callable&& callable, Args&&... args)
{
   const auto result =
      std::invoke(std::forward<Callable>(callable), std::forward<Args>(args)...);

   if (result != expected) throw std::system_error{result, std::system_category()};
}
