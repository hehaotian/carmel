#ifndef GRAEHL_SHARED__PROPERTY_HPP
#define GRAEHL_SHARED__PROPERTY_HPP

/* factory objects for boost property_maps (which have typed values) - e.g. # of states for vertex id -> X map */

#include <boost/version.hpp>
#include <boost/ref.hpp>
#if BOOST_VERSION >= 104000
#include <boost/property_map/property_map.hpp> //boost 1.40
#else
#include <boost/property_map.hpp>
#endif
#include <utility>
#include <vector>

#define GRAEHL_PROPERTY_REF 0
#if GRAEHL_PROPERTY_REF
#include <boost/ref.hpp>
#endif
namespace graehl {

/**
   like boost::identity_map but for non-std::size_t types too
*/
template <class K>
struct IdentityMap {
  //      : boost::put_get_helper<K, IdentityMap> .
  typedef K key_type;
  typedef K value_type;
  typedef K const& reference;
  typedef boost::readable_property_map_tag category;
  inline K const& operator[](K const& key) const { return key; }
};

template <class K>
K const& get(IdentityMap<K>, K const& key) {
  return key;
}


template <class K>  // for random access iterator or integral key K - e.g. you have vertex_descriptor = pointer to array of verts and want an external property map (ArrayPMapImp)
struct OffsetMap {
  K begin;
  unsigned index(K p) const {
    Assert(p>=begin);
    return (unsigned)(p-begin);
  }
  explicit OffsetMap(K beg) : begin(beg) {
  }
  typedef boost::readable_property_map_tag category;
  typedef unsigned value_type;
  typedef K key_type;
  unsigned operator [](K p) const {
    return index(p);
  }
};

template <class K>
unsigned get(OffsetMap<K> k,K p) {
  return k[p];
}


#if GRAEHL_PROPERTY_REF
template <class P>
typename P::value_type get(boost::reference_wrapper<P> p,typename P::key_type k) {
  return get((typename boost::unwrap_reference<T>::type const &)p,k);
}

template <class P>
void put(boost::reference_wrapper<P> p,typename P::key_type k,typename P::value_type v) {
  return put((typename boost::unwrap_reference<T>::type &)p,k,v);
}
#endif


/* usage:
 ArrayPMapImp<V,O> p;
 graph_algo(g,boost::ref(p));
 */
template <class V,class O=boost::identity_property_map>
struct ArrayPMapImp
//: public  boost::put_get_helper<V &,ArrayPMapImp<V,O> >
{
  typedef ArrayPMapImp<V,O> Self;
  typedef boost::reference_wrapper<Self> PropertyMap;
  typedef O offset_map;
  typedef typename O::key_type key_type;
  typedef boost::lvalue_property_map_tag category;
  typedef V value_type;
  typedef V& reference;
  offset_map ind; // should also be copyable
  typedef std::vector<value_type> Vals;
  Vals vals; // copyable!

  explicit ArrayPMapImp(unsigned size=0) : ind(), vals(size) {}
  ArrayPMapImp(unsigned size,offset_map o) : ind(o), vals(size) {}
  operator Vals & ()  {
    return vals;
  }
  V & operator [](key_type k) const {
#ifdef _MSC_VER
#pragma warning( push )
#pragma warning( disable : 4267 )
#endif
    return vals[get(ind,k)];
#ifdef _MSC_VER
#pragma warning( pop )
#endif
  }
  template <class Os>
  void print(Os &o) const {
    o<<vals;
  }
  friend inline std::ostream &operator<<(std::ostream &o,Self const& s) { s.print(o); return o; }
private:
};

template <class V,class O>
V get(const ArrayPMapImp<V,O> &p,typename ArrayPMapImp<V,O>::key_type k) {
  return p[k];
}

template <class V,class O>
void put(ArrayPMapImp<V,O> &p,typename ArrayPMapImp<V,O>::key_type k,V v) {
  p[k]=v;
}

/// constant property map. ignores puts and returns same constant on get
template <class V>
struct ConstPropertyMap {
  typedef boost::writable_property_map_tag category;
  V val;
  explicit ConstPropertyMap(V const& val)
      : val(val) {}
};

template <class V,class Key>
V const& get(ConstPropertyMap<V> const& pmap,Key const&) {
  return pmap.val;
}


template <class V,class Key>
void put(ConstPropertyMap<V> const& pmap,Key const&,V const& ) {}

/// constant property map. ignores puts and returns same constant on get
template <class V>
struct NullPropertyMap {
  typedef boost::writable_property_map_tag category;
};

template <class V,class Key>
V get(NullPropertyMap<V> const& pmap,Key const&) {
  return V();
}

template <class V,class Key,class Val2>
void put(NullPropertyMap<V> const& pmap,Key const&,Val2 const& ) {}

template <class offset_map=boost::identity_property_map>
struct ArrayPMapFactory : public std::pair<unsigned,offset_map> {
  ArrayPMapFactory(unsigned s,offset_map o=offset_map()) : std::pair<unsigned,offset_map>(s,o) {}
  ArrayPMapFactory(const ArrayPMapFactory &o) : std::pair<unsigned,offset_map>(o) {}
  template <class R>
  struct rebind {
    typedef ArrayPMapImp<R,offset_map> implementation;
    typedef boost::reference_wrapper<implementation> reference;
  };
};


/**
   visitor for copying (by index) from one property map to another
*/
template <class P1,class P2>
struct IndexedCopier : public std::pair<P1,P2> {
  IndexedCopier(P1 a_,P2 b_) : std::pair<P1,P2>(a_,b_) {}
  template<class I>
    void operator()(I i) {
      (this->first)[i] = (this->second)[i];
    }
};

template <class P1,class P2>
IndexedCopier<P1,P2> make_indexed_copier(P1 a,P2 b) {
  return IndexedCopier<P1,P2>(a,b);
}

}

namespace boost {
template<class Imp>
struct property_traits<boost::reference_wrapper<Imp> > {
  typedef typename Imp::category category;
  typedef typename Imp::key_type key_type;
  typedef typename Imp::value_type value_type;
};
}


#endif
