# Leap - Electronic Individual Learning Plan Software
# Copyright (C) 2011 South Devon College

# Leap is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Leap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with Leap.  If not, see <http://www.gnu.org/licenses/>.

class Qualification < Eventable

  include MisQualification

  after_create {|qual| qual.events.create!(:event_date => created_at, :transition => qual.predicted? ? :create : :complete)}

  before_save  {|q| q.predicted=true if (Person.user and !Person.user.staff?)}

  validates :title, :presence => true 
  
  attr_accessible :awarding_body, :grade, :predicted, :qual_type, :seen, :title, :created_at

  belongs_to :person

  QOE_LAT = {"GNVQ"          => {"WEIGHT"=>4, "DISTINCTION"=>220, "MERIT"=>184, "PASS"=>160}, 
	     "GCSE"          => {"A"=>52, "B"=>46, "C"=>40, "D"=>34, "WEIGHT"=>1, "E"=>28, "F"=>22, "G"=>16, "A*"=>58, "U"=>0}, 
	     "FIRST DIPLOMA" => {"WEIGHT"=>2, "DISTINCTION"=>136, "MERIT"=>112, "PASS"=>76}, 
	     "DOUBLE GCSE"   => {"A*A*"=>106, "AA"=>104, "BB"=>92, "CC"=>80, "DD"=>68, "EE"=>56, "FF"=>44, "GG"=>32, "NN"=>0, "UU"=>0, "WEIGHT"=>2}, 
	     "SHORT GCSE"    => {"A"=>26, "B"=>23, "C"=>20, "D"=>17, "WEIGHT"=>0.5, "E"=>14, "F"=>11, "G"=>8, "A*"=>29, "U"=>0}
            }

  def body
    [self[:qual_type],self[:title]].reject{|x| x.blank?}.join ": "
  end

  def subtitle
    grade
  end

  def status
    return :complete if seen?
    return :complete if !mis_id.blank?
    return :not_started if predicted?
    return :current
  end

  def title
    return "Qualification" if seen?
    return "Qualification" if !mis_id.blank?
    return ["Predicted","Grade"] if predicted?
    return ["Qualification","(not_seen)"] 
  end

  def lat_score
    begin
      # Only calc lat scores for quals with grades
      return "No Grade" if grade.blank?
      # Only calc lat_scores for quals on entry
      return "Imported Qual" if mis_id 
      # Don't include predicted grades
      return "Predicted Grade" if predicted?
      # Only quals acheived between 16 & 18 years count towards LAT
      years = case person.age_on(Date.civil(2013,9,1))
      when 16 then 1
      when 17 then 2
      when 18 then 3
      else 0
      end
      return "Ineligible Date" unless created_at.between?(Date.civil(2013,8,1) - years.years,Date.today)#civil(2013,9,1))
      # Only return LAT scores if we can work them out from the info we have
      return "No scores for qual type" unless QOE_LAT[qual_type.strip.upcase] 
      return "No scores for this grade" unless QOE_LAT[qual_type.strip.upcase][grade.strip.upcase]
      QOE_LAT[qual_type.strip.upcase][grade.strip.upcase]
    rescue
      return "Unexpected error!"
    end
  end

end
