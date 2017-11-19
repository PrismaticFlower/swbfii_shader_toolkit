#pragma once

#include <string>
#include <type_traits>

template<typename Pod>
inline std::string_view view_pod_as_string(const Pod& pod)
{
   static_assert(std::is_pod_v<std::remove_reference_t<Pod>>,
                 "Type must be plain-old-data.");
   static_assert(!std::is_pointer_v<std::remove_reference_t<Pod>>,
                 "Type can not be a pointer.");

   return {reinterpret_cast<const char*>(&pod), sizeof(Pod)};
}

template<typename Pod>
inline std::string view_pod_as_string(Pod&& pod)
{
   static_assert(std::is_pod_v<std::remove_reference_t<Pod>>,
                 "Type must be plain-old-data.");
   static_assert(!std::is_pointer_v<std::remove_reference_t<Pod>>,
                 "Type can not be rvalue to pointer.");

   return {reinterpret_cast<const char*>(&pod), sizeof(Pod)};
}
