require 'timecop'
require_relative '../lib/timert/application'
require_relative '../lib/timert/database'
require_relative '../lib/timert/database_file'

describe Timert::Application do
  let(:path) { './spec/data/timert' }
  let(:database) { Timert::Database.new(Timert::DatabaseFile.new(path)) }
  let(:app_with_no_args) { Timert::Application.new([], path) }

  after(:each) do
    File.delete(path)
  end

  context 'when initialized with empty arguments' do
    it 'should be initialized without errors' do
      expect { app_with_no_args }.to_not raise_error
    end
  end

  context 'when initialized with start argument' do
    before do
      Timecop.freeze(Time.new(2013, 6, 12, 13, 56))
      @app = Timert::Application.new(["start"], path)
    end

    after do
      Timecop.return
    end

    it 'should perform start operation' do
      expect(database.today.last_start).to eq(Time.now.to_i)
    end

    it 'should have a method that returns hash result' do
      expect(@app.result["message"].instance_of?(String)).to eq(true)
    end

    context 'and then initialized with stop argument' do
      before do
        Timecop.freeze(Time.new(2013, 6, 12, 14, 34))
        @app = Timert::Application.new(["stop"], path)
      end

      after do
        Timecop.return
      end

      it 'should perform stop operation' do
        expect(database.today.last_stop).to eq(Time.now.to_i)
      end

      it 'should have a method that returns hash result' do
        expect(@app.result["message"].instance_of?(String)).to eq(true)
      end
    end

    context 'and then initialized with stop and time argument' do
      before do
        Timecop.freeze(2013, 6, 12, 16, 00)
        @app = Timert::Application.new(["stop", "15:59"], path)
      end

      after do
        Timecop.return
      end

      it 'should stop with given time' do
        expect(database.today.last_stop).to eq(Time.now.to_i - 60)
      end
    end

    context 'and then initialized with stop and invalid time argument' do
      it 'should not raise an error' do
        Timecop.freeze(2013, 6, 12, 15, 00) do
          Timert::Application.new(["stop", "9"], path)
          expect { Timert::Application.new(["stop", "9"], path) }.to_not raise_error
        end
      end
    end
  end

  context 'when initialized with start and time argument' do
    before do
      Timecop.freeze(2013, 3, 20, 16, 00)
      @app = Timert::Application.new(["start", "15:59"], path)
    end

    after do
      Timecop.return
    end

    it 'should start with given time' do
      expect(database.today.last_start).to eq(Time.now.to_i - 60)
    end
  end

  context 'when initialized with start and invalid time argument' do
    before do
      Timecop.freeze(Time.new(2013, 1, 10, 15)) do
        Timert::Application.new(["start"], path)
      end
      Timecop.freeze(Time.new(2013, 1, 10, 16)) do
        Timert::Application.new(["stop"], path)
      end
    end

    it 'should not raise an error' do
      Timecop.freeze(2013, 1, 10, 17, 00) do
        expect { Timert::Application.new(["start", "9"], path) }.to_not raise_error
      end
    end
  end

  context 'when initialized with report argument' do
    before do
      @app = Timert::Application.new(["report"], path)
    end

    it 'should have a method that returns hash result' do
      expect(@app.result["message"].include?("REPORT")).to eq(true)
    end
  end

  context 'when initialized with argument other than start, stop or report' do
    before do
      @app = Timert::Application.new(["testing the new app"], path)
    end

    it 'should add task' do
      expect(database.today.tasks).to eq(["testing the new app"])
    end

    context 'and then initialized with argument that fullfills the same requirements' do
      before do
        @app = Timert::Application.new(["writing emails"], path)
      end

      it 'should add another task' do
        expect(database.today.tasks).to eq(["testing the new app", "writing emails"])
      end
    end

    it 'should have a method that returns hash result' do
      expect(@app.result["message"].instance_of?(String)).to eq(true)
    end
  end
end
