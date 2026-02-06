task embed_drugs: :environment do
  drugs = Drug.all

  drugs.each_slice(15) do |fifteen_drugs|
    fifteen_drugs.each do |drug|
      embedding = RubyLLM.embed("Drug: #{drug.name}. Description: #{drug.description}")
      drug.update(embedding: embedding.vectors)
      puts "Embedded 15 drugs ..."
    end
    sleep(60)
  end
end
