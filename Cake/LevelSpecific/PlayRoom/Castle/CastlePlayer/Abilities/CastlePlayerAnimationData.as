UCLASS(Meta = (AutoExpandCategories = "Basic Attack"))
class UCastleAnimationDataAsset : UDataAsset
{
    UPROPERTY()
    UHazeLocomotionStateMachineAsset StateMachineAsset;
}

UCLASS(Meta = (AutoExpandCategories = "Dash", "Whirlwind"))
class UCastleAnimationBruteDataAsset : UCastleAnimationDataAsset
{
}

UCLASS(Meta = (AutoExpandCategories = "Blink", "FrozenOrb"))
class UCastleAnimationMageDataAsset : UCastleAnimationDataAsset
{
	UPROPERTY(Category = "Blink")
    FCastleAbilityAnimation BlinkExit;

	UPROPERTY(Category = "FrozenOrb")
    FCastleAbilityAnimation FrozenOrb;
}

struct FCastleBasicAttackAnimations
{
	UPROPERTY()
    TArray<UAnimSequence> RandomAnimations;
    UPROPERTY()
	FCastleAbilityAnimationSettings AnimationSettings;
}

struct FCastleAbilityAnimation
{
    UPROPERTY()
    UAnimSequence Animation;
    UPROPERTY()
	FCastleAbilityAnimationSettings AnimationSettings;
}

struct FCastleAbilityAnimationSettings
{
    UPROPERTY()
    float BlendTime = 0.f;
    UPROPERTY()
    float PlayRate = 1.f;
}