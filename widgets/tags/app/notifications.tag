<kor-notifications>

  <ul>
    <li
      each={data in messages}
      class="bg-warning {kor-fade-animation: data.remove}"
      onanimationend={parent.animend}
    >
      <i class="glyphicon glyphicon-exclamation-sign"></i>
      {data.message}
    </li>
  </ul>

  <style type="text/scss">
    kor-notifications {
      ul {
        perspective: 1000px;
        position: absolute;
        top: 0px;
        right: 0px;

        li {
          padding: 1rem;
          list-style-type: none;
        }
      }
    }
  </style>

  <script type="text/coffee">
    self = this
    self.messages = []
    self.history = []

    self.animend = (event) ->
      i = self.messages.indexOf(event.item.data)
      self.history.push(self.messages[i])
      self.messages.splice(i, 1)
      self.update()

    fading = (data) ->
      self.messages.push(data)
      self.update()

      setTimeout(
        (->
          data.remove = true
          self.update()
          # $(li).one 'animationend', (event) ->
          #   console.log 'ae'
        ),
        5000
      )

      # setTimeout(
      #   (->
      #     i = self.messages.indexOf(data)
      #     self.history.push(self.messages[i])
      #     self.messages.splice(i, 1)
      #     self.update()
      #   ),
      #   2900 
      # )

    kor.bus.on 'notify', (data) ->
      type = data.type || 'default'
      if type == 'default' then fading(data)
      self.update()

  </script>

</kor-notifications>