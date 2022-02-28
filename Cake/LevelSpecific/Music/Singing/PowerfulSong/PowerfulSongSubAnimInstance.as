import Peanuts.Animation.AnimationStatics;
import Cake.LevelSpecific.Music.Singing.SingingComponent;

class UPowerfulSongSubAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	USingingComponent SingingComp;

	UPROPERTY()
	FHazePlaySequenceData IKReference;

	UPROPERTY(BlueprintReadOnly)
	FTransform IKTarget;

	UPROPERTY(BlueprintReadOnly)
	float ShuffleRotation = 0.f;

	UPROPERTY(BlueprintReadOnly)
	bool bIsShooting = false;

	// Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{		
		if(OwningActor == nullptr)
			return;

		SingingComp = USingingComponent::Get(OwningActor);
		IKTarget = GetIkBoneOffset(IKReference,0.f,n"RightAttach",n"LeftHand");
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(OwningActor == nullptr)
			return;

		if(SingingComp == nullptr)
			return;

		bIsShooting = SingingComp.bIsShooting;

		ShuffleRotation = SingingComp.ShuffleRotation;
		
		// change it so it matches leos animation
		ShuffleRotation = Math::NormalizeToRange(ShuffleRotation, 0.f, 360.f);
		ShuffleRotation = 1.f - ShuffleRotation;
		ShuffleRotation = ShuffleRotation * 12.f;
	}
}
