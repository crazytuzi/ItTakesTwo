import Vino.Control.DebugShortcutsEnableCapability;

class UDebugControllerSwapCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(CapabilityTags::Debug);

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

	AHazePlayerCharacter PlayerOwner;

	const float TotalTime = 0.45f;
	float TimeLeft = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler Handler = DebugValues.AddFunctionCall(n"SwapController", "SwapController");
		Handler.AddAlwaysValidButton(EHazeDebugAlwaysValidButtonType::SwapControllerOnKeyboard);
		Handler.AddActiveUserIgnoreCategoryButton(EHazeDebugActiveCategoryAlwaysValidButtonType::SwapControllerOnController);
		Handler.DisplayAsDefault();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TimeLeft <= 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

    /* Checks if the Capability should deactivate and stop ticking
    *  Will be called every tick when the capability is activate and before it ticks. The Capability will not tick the same frame as DeactivateLocal or DeactivateFromControl is returned
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TimeLeft <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

		const float Alpha = FMath::EaseOut(0.f, 1.f, TimeLeft / TotalTime, 3.f); 
		const float ArrowSize = 600.f;
		const float LineSize = 10.f;

		// New player
		if(PlayerOwner.GetOtherPlayer().GetDebugFlag(n"DebugDisplayLevel"))
		{
			FVector DrawPosition = PlayerOwner.GetOtherPlayer().GetActorLocation();
			DrawPosition += PlayerOwner.GetOtherPlayer().GetMovementWorldUp() * ((PlayerOwner.GetOtherPlayer().GetCollisionSize().Y * 2) + 50.f);
			const FVector ArrowDir = PlayerOwner.GetOtherPlayer().GetMovementWorldUp();
			const float StartOffset = 0;
			const float EndOffset = FMath::Lerp(StartOffset, 150.f, Alpha);
			System::DrawDebugArrow(DrawPosition + (ArrowDir * EndOffset), DrawPosition + (ArrowDir * StartOffset), ArrowSize, FLinearColor::White, 0, LineSize);
		}

		TimeLeft -= DeltaTime;
	}

	UFUNCTION(NotBlueprintCallable)
	void SwapController()
	{
		if(IsBlocked())
			return;
			
		if(PlayerOwner.HasControl())
		{
			NetShowDebugInfo();

			// Don't activate find other player capability (Eman)
			ConsumeAction(ActionNames::FindOtherPlayer);
			System::ExecuteConsoleCommand("Haze.SwapControllers");
		}	
	}

	UFUNCTION(NetFunction)
	void NetShowDebugInfo()
	{
		if(PlayerOwner.GetOtherPlayer().HasControl())
		{
			TimeLeft = TotalTime;
		}
	}
};