event void FOnDuckArmActivated();
event void FOnDuckArmDeactivated();


class APirateOctopusArmSecondSequence : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = ArmVisualOffset)
	UHazeSkeletalMeshComponentBase OctoArm;

	UPROPERTY()
	FHazePlaySlotAnimationParams PopUpAnim;

	UPROPERTY()
	FOnDuckArmActivated OnDuckArmActivated;

	UPROPERTY()
	FOnDuckArmDeactivated OnDuckArmDeactivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}

	UFUNCTION()
	void InitiateArm(FVector Location, FRotator Rotation)
	{
		OnDuckArmActivated.Broadcast();
		
		SetActorLocationAndRotation(Location, Rotation);

		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"BlendingOutAnim");
		OctoArm.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, PopUpAnim);
	}

	UFUNCTION()
	void BlendingOutAnim()
	{
		OnDuckArmDeactivated.Broadcast();
	}
}