task embed_drugs: :environment do
  drugs = Drug.where(embedding: nil)
  drugs_count = Drug.all.count

  drugs.each_slice(15) do |fifteen_drugs|
    fifteen_drugs.each do |drug|
      embedding = RubyLLM.embed("Drug: #{drug.name}. Description: #{drug.description}", model: "gemini-embedding-001", dimensions: 1536)

      drug.update!(embedding: embedding.vectors)
      print "#{Drug.where.not(embedding: nil).count} out of #{drugs_count} embedded..." + "\r"
    end
    puts "sleeping ..." + "\r"
    count = 0
    60.times do
      sleep(1)
      print (60 - count).to_s + "\r"
      count += 1
    end
  end

end
