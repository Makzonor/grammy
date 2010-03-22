
require 'spec'

require 'lib/grammar'

describe Grammar do

	describe "DEFINITION" do

		it "should define empty grammar" do
			g = Grammar.define :simple do

			end

			g.name.should == :simple
			g.rules.should be_empty
		end

		it "should define grammar with sequence rule via string" do
			g = Grammar.define :simple do
				rule token: 'test'
			end

			g.rules[:token].should be_a Grammar::Sequence
			g.rules[:token].children.should == ['test']
		end

		it "should define grammar with sequence rule via concat" do
			g = Grammar.define :simple do
				rule token: 'test' >> 'other'
			end

			g.rules[:token].should be_a Grammar::Sequence
			g.rules[:token].children.should == ['test','other']
		end

		it "should define grammar with alternative rule via range" do
			g = Grammar.define :simple do
				rule lower: 'a'..'z'
			end

			g.rules[:lower].should be_a Grammar::Alternatives
			g.rules[:lower].children.should == ('a'..'z').to_a
		end

		it "should define grammar with alternative rule via array" do
			g = Grammar.define :simple do
				rule a_or_g: ['a','g']
			end

			g.rules[:a_or_g].should be_a Grammar::Alternatives
			g.rules[:a_or_g].children.should == ['a','g']
		end

		it "should define grammar with alternative rule via symbols" do
			g = Grammar.define :simple do
				rule a: 'a'
				rule b: 'b'
				rule a_or_b: :a | :b
			end

			g.rules[:a_or_b].should be_a Grammar::Alternatives
			g.rules[:a_or_b].children.should == [:a,:b]
		end

		it "should define simple grammar" do
			g = Grammar.define :simple do
				rule digits: (0..9) * (0..16)
				rule lower: 'a'..'z'
				rule upper: 'A'..'Z'
				rule letter: :lower | :upper
				rule ident_start: :letter | '_';
				rule ident_letter: :ident_start | ('0'..'9')
				rule ident: :ident_start >> (:ident_letter * (0..128))
				rule method_suffix: ['!','?']
				rule method_id: :ident >> :method_suffix?
			end

			g.rules[:digits].should be_a Grammar::Repetition
			g.rules[:lower].should be_a Grammar::Alternatives
			g.rules[:ident].should be_a Grammar::Sequence
			g.rules[:method_id].should be_a Grammar::Sequence
			g.rules[:method_suffix].should be_a Grammar::Alternatives

			g.rules.each_pair do |name,rule|
				rule.name.should == name
			end
		end

		it "should raise when duplicate rules" do
			expect{
				Grammar.define :simple do
					rule a: 'a'
					rule a: 'b'
				end
			}.to raise_error
		end

	end

	describe "PARSING" do

		describe 'Rule' do

			it "should match character" do
				g = Grammar.define :simple do
					rule lower: 'a'..'z'
				end

				node = g.rules[:lower].match("some",0)
				node.should be_a AST::Node
				node.match_range.should == (0..1)
				node.name.should == :lower
			end

			it "should match string" do
				g = Grammar.define :simple do
					rule lower: 'a'..'z'
					rule string: :lower * (1..16)
				end

				node = g.rules[:string].match("some",0)
				node.should be_a AST::Node
				node.name.should == :string
				node.match_range.should == (0..4)
			end

			it "should merge nodes" do
				g = Grammar.define :simple do
					helper lower: 'a'..'z'
					rule string: :lower * (1..16)
				end

				node = g.rules[:string].match("some",0)
				puts node.to_s
				node.children.should == ['some']
			end
		
		end

		it "should parse string with constant repetition" do
			g = Grammar.define :simple do
				helper lower: 'a'..'z'
				rule string: :lower * 4
			end

			tree = g.parse("some",rule: :string)
			tree.children.should == ["some"]
		end

		it "should parse string with sequence" do
			g = Grammar.define :simple do
				helper lower: 'a'..'z'
				rule string: :lower >> :lower >> :lower >> :lower
			end

			tree = g.parse("some",rule: :string)
			tree.children.should == ["some"]
		end

		it "should parse string with constant repetition in sequence" do
			g = Grammar.define :simple do
				helper lower: 'a'..'z'
				rule string: :lower*3 >> :lower
			end

			tree = g.parse("some",rule: :string)
			tree.children.should == ["some"]
		end

		it "should parse an identifier" do
			g = Grammar.define :simple do
				helper lower: 'a'..'z'
				helper upper: 'A'..'Z'
				helper letter: :lower | :upper
				helper ident_start: :letter | '_';
				helper ident_letter: :ident_start | ('0'..'9')
				rule ident: :ident_start >> (:ident_letter * (0..128))
			end

			tree = g.parse("some_id0",rule: :ident)
			puts tree.to_s
		end

	end

	describe "AST" do
		
	end

end