module VillagesHelper

  def get_job_icon(job_id)
    case job_id
    when 1
      image_tag('were_wolf.png', class: 'circle')
    when 2
      image_tag('villager.png', class: 'circle')
    when 3
      image_tag('fortune_teller.png', class: 'circle')
    when 4
      image_tag('knight.png', class: 'circle')
    when 5
      image_tag('priest.png', class: 'circle')
    when 6
      image_tag('madman.png', class: 'circle')
    when 7
      image_tag('crazy.png', class: 'circle')
    when 8
      image_tag('pairs.png', class: 'circle')
    when 9
      image_tag('fox.png', class: 'circle')
    end
  end

  def get_job_info(job_id)
    case job_id
    when 1
      '毎晩誰かを襲撃します。'
    when 2
      '何の能力もありません。'
    when 3
      '人狼か人間かを識別します。'
    when 4
      '人狼の襲撃から守ります。'
    when 5
      '死んだ人間を識別できます。'
    when 6
      '人狼陣営の人間です。'
    when 7
      '人狼の正体を知っています。'
    when 8
      'お互いの正体を知っています。'
    when 9
      '第３の陣営です。'
    end
  end
end
