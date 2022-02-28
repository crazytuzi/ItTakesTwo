import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeSnowBallReload;
class USnowBallReloadAnimInstance : UHazeFeatureSubAnimInstance
{

	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureSnowBallReload SnowBallReloadFeature;


	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{

		if(OwningActor == nullptr)
			return;

		SnowBallReloadFeature = Cast<ULocomotionFeatureSnowBallReload>(GetFeatureAsClass(ULocomotionFeatureSnowBallReload::StaticClass()));

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(OwningActor == nullptr)
			return;

	}

}