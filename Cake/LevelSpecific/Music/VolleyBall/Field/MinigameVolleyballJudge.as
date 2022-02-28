
import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;

struct FVolleyballBallTypeProbebility
{
	UPROPERTY()
	TSubclassOf<AMinigameVolleyballBall> Class;
}

UCLASS(hidecategories="Physics Collision Replication Input HLOD Mobile AssetUserData Sockets Clothing ClothingSimulation")
class UMinigameVolleyballJudge : UHazeCharacterSkeletalMeshComponent
{
	default SetVisibility(false);

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem ShowUpEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem DisappearEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams IdleAnimation;
	default IdleAnimation.bLoop = true;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams ThrowBallAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	TArray<FVolleyballBallTypeProbebility> BallTypes;

	UFUNCTION(NotBlueprintCallable)
	void PlayIdleAnimation()
	{
		PlaySlotAnimation(IdleAnimation);
	}

	void PlayThrowAnimation()
	{
		FHazeAnimationDelegate OnComplete;
		OnComplete.BindUFunction(this, n"PlayIdleAnimation");
		PlaySlotAnimation(FHazeAnimationDelegate(), OnComplete, ThrowBallAnimation);
	}

	bool GetBallTypeToSpawn(TSubclassOf<AMinigameVolleyballBall>& Out)
	{
		if(BallTypes.Num() == 0)
			return false;

		int RandomIndex = FMath::RandRange(0, BallTypes.Num() - 1);
		Out = BallTypes[RandomIndex].Class;
		return true;
	}
}