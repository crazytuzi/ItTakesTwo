class UCastleEnemyChargeFeature : UHazeLocomotionFeatureBase
{
    UCastleEnemyChargeFeature()
    {
        Tag = n"CastleEnemyCharge";
    }

	UPROPERTY(Category = "CastleEnemyCharge|Telegraph")
    FHazePlaySequenceData TelegraphEnter;

	UPROPERTY(Category = "CastleEnemyCharge|Telegraph")
    FHazePlaySequenceData TelegraphMH;

	UPROPERTY(Category = "CastleEnemyCharge|Charge")
    FHazePlaySequenceData ChargeEnter;

	UPROPERTY(Category = "CastleEnemyCharge|Charge")
    FHazePlaySequenceData ChargeMH;

	UPROPERTY(Category = "CastleEnemyCharge|Stun")
    FHazePlaySequenceData StunEnter;

	UPROPERTY(Category = "CastleEnemyCharge|Stun")
    FHazePlaySequenceData StunMH;

	UPROPERTY(Category = "CastleEnemyCharge|Stun")
    FHazePlaySequenceData StunRecover;

	UPROPERTY(Category = "CastleEnemyCharge|Turn")
    FHazePlaySequenceData TurnLeft;

	UPROPERTY(Category = "CastleEnemyCharge|Turn")
    FHazePlaySequenceData TurnRight;
};