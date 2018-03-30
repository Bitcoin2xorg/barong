# frozen_string_literal: true

class FakeSMS

  cattr_accessor :messages
  self.messages = []

  def initialize(_account_sid, _auth_token)
  end

  def messages
    self
  end

  def create(res)
    self.class.messages << OpenStruct.new(res)
  end
end
