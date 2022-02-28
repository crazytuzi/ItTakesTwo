UCLASS(Abstract)
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;

event void FOnMagnetismEffectActivated(AActor TargetActor, UMagneticComponent OwnerMagnetComp, UMagneticComponent OtherMagneticComp, AHazePlayerCharacter Player, bool IsInteracting);
event void FOnMagnetismEffectDeactivated();

class AMagneticEffects : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	FOnMagnetismEffectActivated OnMagnetismEffectActivated;

	UPROPERTY()
	FOnMagnetismEffectDeactivated OnMagnetismEffectDeactivated;

	AHazePlayerCharacter Player;
	AActor InteractingActor;

	UMagneticComponent MagnetCompToFocusOn;

	bool bActive = false;
	bool bIsPositive;

	void Initialize(AHazePlayerCharacter OwningPlayer, bool Positive)
	{
		Player = OwningPlayer;
		bIsPositive = Positive;
	}

	void ActivateMagneticEffect(AActor OtherActor, UMagneticComponent MagnetComp, UMagneticComponent OtherMagnetComp, bool IsInteracting)
	{
		if(OtherActor != nullptr)
		{
			InteractingActor = OtherActor;

			bActive = true;
			
			if(MagnetComp != nullptr)
				MagnetCompToFocusOn = MagnetComp;

			OnMagnetismEffectActivated.Broadcast(InteractingActor, MagnetComp, OtherMagnetComp, Player,IsInteracting);
		}
	}

	void DeactivateMagneticEffect()
	{
		InteractingActor = nullptr;
		MagnetCompToFocusOn = nullptr;

		bActive = false;
		OnMagnetismEffectDeactivated.Broadcast();
	}
}