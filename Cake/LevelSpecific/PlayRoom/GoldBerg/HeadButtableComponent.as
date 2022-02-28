import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCranePlatformInteraction;

class UHeadButtableComponent: USceneComponent
{
	UPROPERTY()
	bool OverrideCanBeHeadButted = true;

	bool IsHeadButtingBlockedByCode = false;

	ADinoCranePlatformInteraction DinoPlatform;

	UPROPERTY()
	bool StartWithPlatformInteractionenabled = true;

	UPROPERTY()
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	AVolume FlipCollision;

	UPROPERTY()
	UAkAudioEvent OnGroundSlamAudio;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Cast<ADinoCranePlatformInteraction>(Owner.AttachParentActor) != nullptr)
		{
			DinoPlatform = Cast<ADinoCranePlatformInteraction>(Owner.AttachParentActor);
		}

		if (!StartWithPlatformInteractionenabled && DinoPlatform != nullptr)
		{
			DinoPlatform.Interaction.Disable(n"DinoPlatform");
		}

		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);

		if (FlipCollision != nullptr)
		{
			FlipCollision.SetActorEnableCollision(false);
		}
	}

	UFUNCTION()
	void HeadButtEffectsAreDone()
	{

		// if (DinoPlatform != nullptr)
		// {
		// 	DinoPlatform.Interaction.Enable(n"WaitingForApproval");
		// }
		if (FlipCollision != nullptr)
		{
			FlipCollision.SetActorEnableCollision(false);
		}
	}

	UFUNCTION(BlueprintEvent)
	void PlayHeadButtEffects()
	{
		if (DinoPlatform != nullptr)
		{

			if(DinoPlatform.Interaction.IsDisabled(n"DinoPlatform"))
			{
				DinoPlatform.Interaction.Enable(n"DinoPlatform");
			}
			else
			{
				DinoPlatform.Interaction.Disable(n"DinoPlatform");
			}
		}

		if (FlipCollision != nullptr)
		{
			FlipCollision.SetActorEnableCollision(true);
		}
	}

	UFUNCTION(BlueprintEvent)
	void ReverseHeadButtEffects()
	{

	}

	UFUNCTION(BlueprintEvent)
	void PlayFailedHeadButtEffects()
	{
		
	}
}