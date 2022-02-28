import Cake.LevelSpecific.Music.Cymbal.Cymbal;

class UCymbalDebugCapability : UHazeDebugCapability
{
	ACymbal Cymbal;

	bool bDrawDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cymbal = Cast<ACymbal>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler TogleDrawDebugHandler = DebugValues.AddFunctionCall(n"ToggleDrawDebug", "Toggle Draw Debug");

		TogleDrawDebugHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Cymbal");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bDrawDebug)
			DrawDebug();
	}

	private void DrawDebug()
	{
		if(Cymbal.AutoAimTarget != nullptr)
		{
			FVector Extent, Origin;
			Cymbal.AutoAimTarget.Owner.GetActorBounds(false, Origin, Extent);
			System::DrawDebugBox(Origin, Extent, FLinearColor::Red, FRotator::ZeroRotator, 0, 6);
		}

		if(Cymbal.bIsMoving)
		{
			if(Cymbal.bReturnToOwner)
			{
				System::DrawDebugLine(Cymbal.StartLocation, Cymbal.HitLocation, FLinearColor::Green);
				System::DrawDebugLine(Cymbal.HitLocation, Cymbal.ActorCenterLocation, FLinearColor::Green);
			}
			else
			{
				System::DrawDebugLine(Cymbal.StartLocation, Cymbal.ActorCenterLocation, FLinearColor::Green);
			}
		}
	}

	UFUNCTION()
	private void ToggleDrawDebug()
	{
		bDrawDebug = !bDrawDebug;
		Cymbal.bDebugDrawMovement = bDrawDebug;
	}
}
