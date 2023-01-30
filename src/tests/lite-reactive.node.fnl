(import-macros {: mk-test} :test)
(local {: _tests} (require :lite-reactive.node))
(local test (require :u-test))
(local inspect (require :inspect))
(mk-test
  :lite-reactive.node.is-props-table
  (test.equal 
    (_tests.is-props-table {:a 1})
    true)
  (test.equal
    (_tests.is-props-table {:type :atom})
    false)
  (test.equal
    (_tests.is-props-table [{:type :atom}])
    false))

(mk-test
  :lite-reactive.node.prepare-props
  (let [props (_tests.prepare-props {:a 1})]
    (test.equal props.a 1))
  (let [props (_tests.prepare-props 
                ;;mock node
                {:type :atom})]
    (test.is_not_nil props.children))
  (let [props (_tests.prepare-props
                [{:type :atom}])]
    (test.is_not_nil props.children))
  (let [props (_tests.prepare-props
                {:a 1}
                {:type :atom}
                {:type :atom})]
    (test.equal props.a 1)
    (test.equal (length props.children) 2)) 
  ;;nested
  (let [props (_tests.prepare-props
                {:a 1}
                [
                  {:type :atom}
                  [{:type :atom}]
                  {:type :atom}])]
    (test.equal props.a 1)
    (test.equal (length props.children) 3))) 
