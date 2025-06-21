import 'dart:ui';
import 'package:sentiment_dart/sentiment_dart.dart';
import 'package:flutter/material.dart';
import '../models/sentiment_model.dart';

class SentimentService {
  static final Map<String, SentimentModel> _cache = {};

  // Horoscope-specific word lists for accurate sentiment analysis
  static const List<String> _positiveWords = [
    // Core positive emotions and outcomes
    'growth', 'opportunity', 'love', 'joy', 'success', 'harmony', 'healing', 
    'balance', 'clarity', 'luck', 'optimistic', 'fortunate', 'achievement', 
    'confidence', 'courage', 'strength', 'support', 'breakthrough', 'inspiration', 
    'peace', 'attraction', 'happiness', 'celebration', 'advancement', 'progress', 
    'stability', 'fulfillment', 'resolve', 'improvement', 'gain', 'reward', 'enlightenment',
    
    // Relationships and social
    'romance', 'friendship', 'connection', 'bonding', 'intimacy', 'trust', 'loyalty',
    'partnership', 'unity', 'cooperation', 'understanding', 'empathy', 'compassion',
    'affection', 'warmth', 'kindness', 'generosity', 'gratitude', 'appreciation',
    'admiration', 'devotion', 'commitment', 'reconciliation', 'forgiveness',
    
    // Career and finance
    'promotion', 'raise', 'bonus', 'profit', 'prosperity', 'wealth', 'abundance',
    'investment', 'returns', 'earnings', 'income', 'recognition', 'accomplishment',
    'expertise', 'skill', 'talent', 'creativity', 'innovation', 'leadership',
    'authority', 'influence', 'reputation', 'status', 'prestige', 'excellence',
    
    // Health and wellness
    'vitality', 'energy', 'wellness', 'fitness', 'recovery', 'renewal', 'rejuvenation',
    'restoration', 'vigor', 'stamina', 'immunity', 'regeneration', 'therapy',
    'relief', 'comfort', 'relaxation', 'serenity', 'tranquility', 'calmness',
    
    // Personal development
    'wisdom', 'knowledge', 'learning', 'education', 'growth', 'development',
    'evolution', 'transformation', 'awakening', 'realization', 'discovery',
    'insight', 'revelation', 'epiphany', 'understanding', 'comprehension',
    'mastery', 'perfection', 'excellence', 'achievement', 'attainment',
    
    // Spiritual and emotional
    'blessing', 'grace', 'divine', 'sacred', 'holy', 'spiritual', 'transcendence',
    'elevation', 'upliftment', 'inspiration', 'motivation', 'encouragement',
    'hope', 'faith', 'belief', 'optimism', 'positivity', 'brightness',
    'radiance', 'glow', 'shine', 'sparkle', 'brilliance', 'magnificence',
    
    // Action and movement
    'advance', 'progress', 'move', 'flow', 'soar', 'rise', 'ascend', 'climb',
    'reach', 'achieve', 'attain', 'obtain', 'acquire', 'secure', 'capture',
    'win', 'triumph', 'conquer', 'overcome', 'surpass', 'exceed', 'excel',
    
    // Emotional states
    'elated', 'thrilled', 'excited', 'enthusiastic', 'passionate', 'eager',
    'delighted', 'pleased', 'satisfied', 'content', 'fulfilled', 'complete',
    'whole', 'perfect', 'flawless', 'ideal', 'wonderful', 'amazing',
    'fantastic', 'incredible', 'outstanding', 'exceptional', 'remarkable',
    
    // Communication and expression
    'articulate', 'eloquent', 'expressive', 'clear', 'precise', 'effective',
    'persuasive', 'convincing', 'compelling', 'influential', 'inspiring',
    'motivating', 'encouraging', 'uplifting', 'supportive', 'helpful',
    
    // Timing and opportunity
    'timely', 'opportune', 'favorable', 'auspicious', 'promising', 'bright',
    'golden', 'perfect', 'ideal', 'optimal', 'peak', 'prime', 'best',
    'supreme', 'ultimate', 'maximum', 'highest', 'greatest', 'finest',
    
    // Mental and emotional clarity
    'focused', 'concentrated', 'alert', 'sharp', 'keen', 'astute', 'perceptive',
    'intuitive', 'insightful', 'wise', 'intelligent', 'brilliant', 'clever',
    'smart', 'gifted', 'talented', 'capable', 'competent', 'skilled',
    
    // Abundance and prosperity
    'rich', 'wealthy', 'prosperous', 'abundant', 'plentiful', 'bountiful',
    'generous', 'lavish', 'luxurious', 'opulent', 'magnificent', 'grand',
    'glorious', 'splendid', 'gorgeous', 'beautiful', 'stunning', 'breathtaking',
    
    // Freedom and liberation
    'free', 'liberated', 'independent', 'autonomous', 'unrestricted', 'unbounded',
    'limitless', 'infinite', 'endless', 'eternal', 'everlasting', 'permanent',
    'lasting', 'enduring', 'sustainable', 'solid', 'strong', 'powerful',
    
    // New beginnings
    'fresh', 'new', 'novel', 'original', 'innovative', 'creative', 'inventive',
    'pioneering', 'groundbreaking', 'revolutionary', 'transformative', 'renewing',
    'refreshing', 'invigorating', 'energizing', 'stimulating', 'exciting',
    
    // Success and victory
    'victorious', 'successful', 'accomplished', 'achieved', 'fulfilled', 'realized',
    'completed', 'finished', 'concluded', 'resolved', 'settled', 'solved',
    'fixed', 'healed', 'restored', 'repaired', 'mended', 'improved',
    
    // Joy and celebration
    'celebrate', 'rejoice', 'cheer', 'applaud', 'praise', 'honor', 'salute',
    'toast', 'commemorate', 'mark', 'acknowledge', 'recognize', 'appreciate',
    'value', 'treasure', 'cherish', 'adore', 'worship', 'revere',
    
    // Protection and safety
    'protected', 'safe', 'secure', 'guarded', 'shielded', 'defended', 'preserved',
    'maintained', 'sustained', 'supported', 'backed', 'endorsed', 'approved',
    'validated', 'confirmed', 'verified', 'guaranteed', 'assured', 'certain',
    
    // Beauty and aesthetics
    'beautiful', 'gorgeous', 'stunning', 'attractive', 'appealing', 'charming',
    'elegant', 'graceful', 'refined', 'sophisticated', 'stylish', 'fashionable',
    'trendy', 'modern', 'contemporary', 'fresh', 'vibrant', 'lively',
    
    // Communication success
    'eloquent', 'articulate', 'expressive', 'clear', 'coherent', 'logical',
    'rational', 'reasonable', 'sensible', 'practical', 'realistic', 'achievable',
    'attainable', 'possible', 'feasible', 'viable', 'workable', 'effective',
    
    // Emotional fulfillment
    'satisfied', 'content', 'pleased', 'happy', 'joyful', 'blissful', 'ecstatic',
    'euphoric', 'elated', 'uplifted', 'elevated', 'inspired', 'motivated',
    'encouraged', 'empowered', 'strengthened', 'fortified', 'invigorated',
    
    // Mental attributes
    'wise', 'intelligent', 'smart', 'clever', 'brilliant', 'genius', 'gifted',
    'talented', 'skilled', 'expert', 'professional', 'qualified', 'competent',
    'capable', 'able', 'efficient', 'productive', 'successful', 'effective'
  ];

  static const List<String> _negativeWords = [
    // Core negative emotions and outcomes
    'conflict', 'loss', 'delay', 'stress', 'misunderstanding', 'fear', 'isolation', 
    'struggle', 'anger', 'confusion', 'disappointment', 'risk', 'tension', 'jealousy', 
    'instability', 'caution', 'obstacle', 'challenge', 'argument', 'sadness', 'worry', 
    'fatigue', 'frustration', 'burden', 'betrayal', 'failure', 'blockage', 'pressure', 
    'rejection', 'doubt', 'negativity', 'imbalance',
    
    // Relationships and social problems
    'breakup', 'divorce', 'separation', 'abandonment', 'loneliness', 'alienation',
    'hostility', 'resentment', 'hatred', 'spite', 'malice', 'revenge', 'grudge',
    'bitterness', 'cynicism', 'mistrust', 'suspicion', 'paranoia', 'insecurity',
    'vulnerability', 'weakness', 'fragility', 'sensitivity', 'hurt', 'pain',
    
    // Career and financial troubles
    'unemployment', 'bankruptcy', 'debt', 'poverty', 'loss', 'deficit', 'shortage',
    'scarcity', 'lack', 'want', 'need', 'deprivation', 'hardship', 'struggle',
    'difficulty', 'problem', 'issue', 'crisis', 'emergency', 'disaster',
    'catastrophe', 'tragedy', 'misfortune', 'bad luck', 'curse', 'doom',
    
    // Health and wellness issues
    'illness', 'disease', 'sickness', 'infection', 'injury', 'wound', 'trauma',
    'damage', 'harm', 'hurt', 'ache', 'pain', 'suffering', 'agony', 'torture',
    'exhaustion', 'fatigue', 'weakness', 'frailty', 'deterioration', 'decline',
    
    // Personal setbacks
    'ignorance', 'stupidity', 'foolishness', 'mistake', 'error', 'blunder',
    'oversight', 'negligence', 'carelessness', 'recklessness', 'imprudence',
    'indiscretion', 'misjudgment', 'miscalculation', 'misestimation', 'underestimation',
    'overestimation', 'delusion', 'illusion', 'fantasy', 'unreality', 'falseness',
    
    // Spiritual and emotional darkness
    'curse', 'evil', 'wickedness', 'sin', 'guilt', 'shame', 'regret', 'remorse',
    'sorrow', 'grief', 'mourning', 'despair', 'hopelessness', 'helplessness',
    'powerlessness', 'weakness', 'defeat', 'surrender', 'submission', 'resignation',
    'capitulation', 'giving up', 'quitting', 'abandoning', 'deserting', 'leaving',
    
    // Action and movement problems
    'stuck', 'trapped', 'imprisoned', 'confined', 'restricted', 'limited',
    'constrained', 'hindered', 'obstructed', 'blocked', 'prevented', 'stopped',
    'halted', 'paused', 'delayed', 'postponed', 'cancelled', 'abandoned',
    'discontinued', 'terminated', 'ended', 'finished', 'closed', 'shut',
    
    // Emotional states
    'depressed', 'anxious', 'worried', 'stressed', 'overwhelmed', 'burdened',
    'pressured', 'strained', 'tense', 'nervous', 'agitated', 'disturbed',
    'upset', 'troubled', 'bothered', 'annoyed', 'irritated', 'frustrated',
    'angry', 'furious', 'enraged', 'livid', 'irate', 'mad', 'crazy',
    
    // Communication failures
    'misunderstood', 'misinterpreted', 'confused', 'unclear', 'ambiguous',
    'vague', 'obscure', 'hidden', 'secret', 'mysterious', 'puzzling',
    'perplexing', 'bewildering', 'baffling', 'confusing', 'complicated',
    'complex', 'difficult', 'hard', 'tough', 'challenging', 'demanding',
    
    // Timing and missed opportunities
    'late', 'delayed', 'postponed', 'missed', 'lost', 'wasted', 'squandered',
    'blown', 'ruined', 'destroyed', 'damaged', 'broken', 'shattered',
    'crushed', 'smashed', 'demolished', 'devastated', 'annihilated', 'obliterated',
    
    // Mental and emotional confusion
    'confused', 'bewildered', 'perplexed', 'puzzled', 'baffled', 'mystified',
    'lost', 'disoriented', 'scattered', 'distracted', 'unfocused', 'unclear',
    'muddled', 'jumbled', 'mixed up', 'chaotic', 'disorganized', 'messy',
    
    // Scarcity and poverty
    'poor', 'broke', 'bankrupt', 'destitute', 'impoverished', 'needy',
    'wanting', 'lacking', 'missing', 'absent', 'gone', 'lost', 'vanished',
    'disappeared', 'faded', 'diminished', 'reduced', 'decreased', 'lowered',
    
    // Restriction and limitation
    'bound', 'tied', 'chained', 'shackled', 'imprisoned', 'caged', 'trapped',
    'stuck', 'frozen', 'paralyzed', 'immobilized', 'disabled', 'handicapped',
    'impaired', 'damaged', 'broken', 'defective', 'faulty', 'flawed',
    
    // Endings and destruction
    'dead', 'dying', 'death', 'ending', 'termination', 'conclusion', 'finish',
    'completion', 'closure', 'shutdown', 'breakdown', 'collapse', 'fall',
    'crash', 'failure', 'defeat', 'loss', 'ruin', 'destruction',
    
    // Conflict and opposition
    'fight', 'battle', 'war', 'combat', 'struggle', 'clash', 'collision',
    'confrontation', 'opposition', 'resistance', 'rebellion', 'revolt',
    'uprising', 'protest', 'objection', 'complaint', 'criticism', 'attack',
    
    // Isolation and abandonment
    'alone', 'lonely', 'isolated', 'abandoned', 'deserted', 'forsaken',
    'neglected', 'ignored', 'overlooked', 'forgotten', 'dismissed', 'rejected',
    'refused', 'denied', 'declined', 'turned down', 'rebuffed', 'spurned',
    
    // Danger and threat
    'dangerous', 'risky', 'hazardous', 'perilous', 'threatening', 'menacing',
    'intimidating', 'scary', 'frightening', 'terrifying', 'horrifying', 'shocking',
    'disturbing', 'upsetting', 'troubling', 'worrying', 'concerning', 'alarming',
    
    // Ugliness and unpleasantness
    'ugly', 'hideous', 'repulsive', 'disgusting', 'revolting', 'nauseating',
    'sickening', 'appalling', 'horrible', 'terrible', 'awful', 'dreadful',
    'ghastly', 'grim', 'bleak', 'dark', 'gloomy', 'depressing',
    
    // Communication breakdown
    'silent', 'mute', 'speechless', 'tongue-tied', 'inarticulate', 'incoherent',
    'unintelligible', 'incomprehensible', 'meaningless', 'nonsensical', 'absurd',
    'ridiculous', 'foolish', 'silly', 'stupid', 'idiotic', 'moronic', 'dumb',
    
    // Emotional emptiness
    'empty', 'hollow', 'void', 'vacant', 'blank', 'barren', 'sterile',
    'lifeless', 'dead', 'cold', 'frozen', 'numb', 'indifferent', 'apathetic',
    'uncaring', 'heartless', 'cruel', 'harsh', 'brutal', 'savage',
    
    // Mental deficiencies
    'ignorant', 'stupid', 'dumb', 'foolish', 'silly', 'naive', 'gullible',
    'credulous', 'simple', 'slow', 'dense', 'thick', 'dim', 'dull',
    'boring', 'tedious', 'monotonous', 'repetitive', 'mundane', 'ordinary'
  ];

  static const List<String> _moderateWords = [
    // Core neutral and transitional concepts
    'change', 'reflection', 'patience', 'routine', 'choices', 'communication', 
    'timing', 'evaluation', 'shift', 'adjustment', 'compromise', 'pause', 'decision', 
    'transition', 'learning', 'preparation', 'observation', 'introspection', 'calm', 
    'realignment', 'reconsider', 'plan', 'neutral', 'ordinary', 'steady', 'adapt', 
    'wait', 'middle', 'steady pace',
    
    // Contemplation and consideration
    'think', 'ponder', 'contemplate', 'meditate', 'reflect', 'consider',
    'examine', 'analyze', 'study', 'review', 'assess', 'evaluate',
    'judge', 'weigh', 'measure', 'compare', 'contrast', 'distinguish',
    'differentiate', 'separate', 'divide', 'categorize', 'classify', 'organize',
    
    // Time and timing
    'meanwhile', 'currently', 'presently', 'now', 'today', 'temporary',
    'brief', 'short', 'quick', 'fast', 'slow', 'gradual', 'progressive',
    'step-by-step', 'incremental', 'phase', 'stage', 'period', 'duration',
    'interval', 'moment', 'instant', 'second', 'minute', 'hour',
    
    // Planning and preparation
    'prepare', 'plan', 'organize', 'arrange', 'schedule', 'coordinate',
    'structure', 'order', 'sequence', 'priority', 'importance', 'significance',
    'relevance', 'connection', 'relationship', 'association', 'link', 'tie',
    'bond', 'attachment', 'involvement', 'participation', 'engagement', 'activity',
    
    // Learning and development
    'learn', 'study', 'practice', 'exercise', 'train', 'develop',
    'improve', 'enhance', 'refine', 'polish', 'perfect', 'master',
    'skill', 'ability', 'capacity', 'potential', 'possibility', 'chance',
    'opportunity', 'option', 'alternative', 'choice', 'selection', 'preference',
    
    // Communication and interaction
    'speak', 'talk', 'discuss', 'converse', 'chat', 'dialogue',
    'exchange', 'share', 'express', 'communicate', 'convey', 'transmit',
    'deliver', 'present', 'show', 'display', 'demonstrate', 'illustrate',
    'explain', 'describe', 'detail', 'outline', 'summarize', 'conclude',
    
    // Movement and change
    'move', 'shift', 'transfer', 'relocate', 'migrate', 'travel',
    'journey', 'trip', 'visit', 'explore', 'discover', 'find',
    'locate', 'identify', 'recognize', 'notice', 'observe', 'see',
    'watch', 'look', 'view', 'examine', 'inspect', 'investigate',
    
    // Balance and moderation
    'balance', 'equilibrium', 'stability', 'steadiness', 'consistency', 'regularity',
    'pattern', 'rhythm', 'cycle', 'rotation', 'repetition', 'frequency',
    'rate', 'speed', 'pace', 'tempo', 'timing', 'schedule',
    'agenda', 'program', 'itinerary', 'calendar', 'timeline', 'deadline',
    
    // States of being
    'exist', 'be', 'remain', 'stay', 'continue', 'persist',
    'endure', 'last', 'survive', 'maintain', 'preserve', 'keep',
    'hold', 'retain', 'save', 'store', 'contain', 'include',
    'involve', 'require', 'need', 'want', 'desire', 'wish',
    
    // Evaluation and assessment
    'assess', 'evaluate', 'judge', 'rate', 'rank', 'grade',
    'score', 'measure', 'quantify', 'calculate', 'compute', 'estimate',
    'approximate', 'guess', 'predict', 'forecast', 'project', 'anticipate',
    'expect', 'assume', 'suppose', 'believe', 'think', 'feel',
    
    // Process and procedure
    'process', 'procedure', 'method', 'technique', 'approach', 'strategy',
    'tactic', 'plan', 'scheme', 'system', 'structure', 'framework',
    'format', 'style', 'manner', 'way', 'mode', 'means',
    'tool', 'instrument', 'device', 'equipment', 'material', 'resource',
    
    // Information and knowledge
    'information', 'data', 'facts', 'details', 'specifics', 'particulars',
    'elements', 'components', 'parts', 'pieces', 'sections', 'segments',
    'portions', 'fragments', 'bits', 'pieces', 'chunks', 'blocks',
    'units', 'items', 'objects', 'things', 'stuff', 'matter',
    
    // Relationship dynamics
    'relationship', 'connection', 'association', 'partnership', 'collaboration',
    'cooperation', 'coordination', 'teamwork', 'unity', 'harmony', 'agreement',
    'consensus', 'understanding', 'compromise', 'negotiation', 'discussion', 'dialogue',
    'conversation', 'exchange', 'interaction', 'communication', 'contact', 'touch',
    
    // Choice and decision
    'choose', 'select', 'pick', 'decide', 'determine', 'resolve',
    'settle', 'conclude', 'finalize', 'complete', 'finish', 'end',
    'stop', 'halt', 'pause', 'break', 'rest', 'relax',
    'calm', 'quiet', 'peaceful', 'serene', 'tranquil', 'still',
    
    // Routine and habit
    'routine', 'habit', 'custom', 'tradition', 'practice', 'exercise',
    'activity', 'action', 'behavior', 'conduct', 'performance', 'execution',
    'implementation', 'application', 'use', 'usage', 'utilization', 'employment',
    'operation', 'function', 'work', 'job', 'task', 'duty',
    
    // Adaptation and flexibility
    'adapt', 'adjust', 'modify', 'alter', 'change', 'transform',
    'convert', 'switch', 'shift', 'move', 'transfer', 'relocate',
    'replace', 'substitute', 'exchange', 'swap', 'trade', 'deal',
    'transaction', 'business', 'commerce', 'industry', 'sector', 'field',
    
    // Observation and awareness
    'observe', 'watch', 'monitor', 'track', 'follow', 'pursue',
    'seek', 'search', 'look', 'find', 'discover', 'uncover',
    'reveal', 'expose', 'show', 'display', 'present', 'offer',
    'provide', 'supply', 'give', 'deliver', 'hand', 'pass',
    
    // Support and assistance
    'support', 'help', 'assist', 'aid', 'serve', 'contribute',
    'participate', 'engage', 'involve', 'include', 'contain', 'hold',
    'carry', 'bear', 'sustain', 'maintain', 'preserve', 'protect',
    'defend', 'guard', 'shield', 'cover', 'hide', 'conceal',
    
    // Understanding and comprehension
    'understand', 'comprehend', 'grasp', 'realize', 'recognize', 'acknowledge',
    'accept', 'approve', 'agree', 'consent', 'permit', 'allow',
    'enable', 'facilitate', 'ease', 'simplify', 'clarify', 'explain',
    'interpret', 'translate', 'convert', 'transform', 'change', 'modify',
    
    // Basic actions and states
    'walk', 'run', 'sit', 'stand', 'lie', 'sleep',
    'wake', 'rise', 'fall', 'drop', 'lift', 'raise',
    'lower', 'reduce', 'increase', 'grow', 'develop', 'expand'
  ];

  /// Analyzes the sentiment of the given text
  static SentimentModel analyzeText(String text) {
    // Check cache first
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }

    try {
      // Clean and prepare text for analysis
      final cleanText = _preprocessText(text);
      
      // Use horoscope-specific analysis for better accuracy
      final score = _analyzeHoroscopeSpecificSentiment(cleanText);
      
      // Create sentiment model
      final sentimentModel = SentimentModel.fromAnalysis(text, score);
      
      // Cache the result
      _cache[text] = sentimentModel;
      
      return sentimentModel;
    } catch (e) {
      // Return moderate sentiment on error
      final fallbackModel = SentimentModel(
        text: text,
        type: SentimentType.moderate,
        score: 0.0,
        confidence: 0.0,
      );
      
      _cache[text] = fallbackModel;
      return fallbackModel;
    }
  }

  /// Analyzes horoscope text specifically using custom word lists
  static double _analyzeHoroscopeSpecificSentiment(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    
    int positiveCount = 0;
    int negativeCount = 0;
    int moderateCount = 0;
    int totalSentimentWords = 0;

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      
      if (_positiveWords.contains(cleanWord)) {
        positiveCount++;
        totalSentimentWords++;
      } else if (_negativeWords.contains(cleanWord)) {
        negativeCount++;
        totalSentimentWords++;
      } else if (_moderateWords.contains(cleanWord)) {
        moderateCount++;
        totalSentimentWords++;
      }
    }

    // If no sentiment words found, fall back to general sentiment analysis
    if (totalSentimentWords == 0) {
      final result = Sentiment.analysis(text);
      return _calculateNormalizedScore(result);
    }

    // Calculate weighted sentiment score
    double score = 0.0;
    
    if (totalSentimentWords > 0) {
      final positiveWeight = positiveCount / totalSentimentWords;
      final negativeWeight = negativeCount / totalSentimentWords;
      final moderateWeight = moderateCount / totalSentimentWords;
      
      // Positive contributes +1, negative contributes -1, moderate contributes 0
      score = (positiveWeight * 1.0) + (negativeWeight * -1.0) + (moderateWeight * 0.0);
      
      // Apply intensity based on word count for confidence
      final intensity = (totalSentimentWords / words.length).clamp(0.0, 1.0);
      score *= intensity;
    }

    return score.clamp(-1.0, 1.0);
  }

  /// Analyzes horoscope text specifically
  static SentimentModel analyzeHoroscope(String horoscopeText) {
    // Remove horoscope-specific noise words that might affect sentiment
    final cleanedText = _cleanHoroscopeText(horoscopeText);
    return analyzeText(cleanedText);
  }

  /// Preprocesses text for better sentiment analysis
  static String _preprocessText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }

  /// Cleans horoscope-specific text
  static String _cleanHoroscopeText(String text) {
    // Remove common horoscope filler words that don't carry sentiment
    final fillerWords = [
      'today', 'tomorrow', 'this week', 'this month',
      'stars', 'planets', 'cosmic', 'universe', 'energy',
      'zodiac', 'horoscope', 'astrology', 'celestial',
      'mercury', 'venus', 'mars', 'jupiter', 'saturn',
      'uranus', 'neptune', 'pluto', 'sun', 'moon',
      'rising', 'sign', 'house', 'aspect', 'transit'
    ];
    
    String cleaned = text.toLowerCase();
    for (final word in fillerWords) {
      cleaned = cleaned.replaceAll(RegExp('\\b$word\\b'), '');
    }
    
    return cleaned.trim();
  }

  /// Calculates normalized sentiment score from SentimentResult
  static double _calculateNormalizedScore(SentimentResult result) {
    final score = result.score;
    final comparative = result.comparative;
    
    // Use comparative score which is normalized by word count
    // Clamp between -1 and 1 for consistency
    return comparative.clamp(-1.0, 1.0);
  }

  /// Gets sentiment color based on type
  static Map<String, dynamic> getSentimentColors(SentimentType type) {
    switch (type) {
      case SentimentType.positive:
        return {
          'primary': const Color(0xFF22c55e), // Green
          'secondary': const Color(0xFF16a34a),
          'background': const Color(0xFF22c55e).withValues(alpha: 0.1),
          'text': const Color(0xFF15803d),
        };
      case SentimentType.negative:
        return {
          'primary': const Color(0xFFef4444), // Red
          'secondary': const Color(0xFFdc2626),
          'background': const Color(0xFFef4444).withValues(alpha: 0.1),
          'text': const Color(0xFFb91c1c),
        };
      case SentimentType.moderate:
        return {
          'primary': const Color(0xFFf59e0b), // Orange
          'secondary': const Color(0xFFd97706),
          'background': const Color(0xFFf59e0b).withValues(alpha: 0.1),
          'text': const Color(0xFFb45309),
        };
    }
  }

  /// Gets detailed sentiment analysis breakdown
  static Map<String, dynamic> getDetailedAnalysis(String text) {
    final cleanText = _cleanHoroscopeText(_preprocessText(text));
    final words = cleanText.split(RegExp(r'\s+'));
    
    final List<String> foundPositive = [];
    final List<String> foundNegative = [];
    final List<String> foundModerate = [];

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      
      if (_positiveWords.contains(cleanWord)) {
        foundPositive.add(cleanWord);
      } else if (_negativeWords.contains(cleanWord)) {
        foundNegative.add(cleanWord);
      } else if (_moderateWords.contains(cleanWord)) {
        foundModerate.add(cleanWord);
      }
    }

    return {
      'positive_words': foundPositive,
      'negative_words': foundNegative,
      'moderate_words': foundModerate,
      'total_words': words.length,
      'sentiment_words': foundPositive.length + foundNegative.length + foundModerate.length,
    };
  }

  /// Clears the sentiment cache
  static void clearCache() {
    _cache.clear();
  }
}
