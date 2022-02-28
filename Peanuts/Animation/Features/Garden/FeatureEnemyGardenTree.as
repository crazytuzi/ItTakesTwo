struct FStructEnemyGardenTreeAnimations
{

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData MovementBlendspace;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Attack01;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData AttackChargeStart;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData AttackCharge;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData AttackChargeStop;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData HitByVineSling;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData HitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData AdditiveHitReaction;

	// Mh that starts playing as soon as the player triggers an attack
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData ShieldBlock;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData ShieldStruggleEnter;

	// Mh that starts playing when the player has locked the vine on the shield
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData ShieldStruggle;

	// Mh that starts playing when the player has locked the vine on the shield to long
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData ShieldBreakOut;

	// Animation to play once the sickle hits the enemy
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData HitReactionShield;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData AdditiveShieldHitReaction;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Death;
}

class UFeatureEnemyGardenTree : UDataAsset 
{
	UPROPERTY()
	FStructEnemyGardenTreeAnimations Animations;
	
}