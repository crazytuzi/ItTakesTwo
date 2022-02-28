import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailWeaponStatics;

UCLASS(abstract)
class UNailUpdateRecallWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailRecall");
	default CapabilityTags.Add(n"NailRecallWidget");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";

	UPROPERTY(BlueprintReadOnly, Category = "Widget")
	TSubclassOf<UNailRecallWidget> NailRecallWidgetClass;

	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	TArray<ANailWeaponActor> AllNails;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WielderComp.bAiming)
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.NailsThrown.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;

		if(IsActioning(CapabilityTags::Interaction))
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.IsRecallCooldownActive())
			return EHazeNetworkActivation::DontActivate;

 		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(CapabilityTags::Interaction))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WielderComp.NailsThrown.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!WielderComp.bAiming)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// get all nails in case we acquired a new nails since last time
		AllNails = GetAllNails(Player);

		// Add all widgets while aiming
		for(ANailWeaponActor NailIter : AllNails)
			AddRecallWidget(NailIter);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// remove all widgets when we aren't aiming anymore
		for(ANailWeaponActor NailIter : AllNails)
			RemoveRecallWidget(NailIter);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateWidgets();
	}

	void UpdateWidgets()
	{
		const FVector CamOrigin = Player.GetPlayerViewLocation();
		const FVector CamDirection = Player.GetPlayerViewRotation().Vector();

		// filter out which nails we potentially want a widget on
		TArray<ANailWeaponActor> NailsToQuery;
		NailsToQuery.Reserve(AllNails.Num());
		for(ANailWeaponActor NailIter : AllNails)
		{
			if(WielderComp.IsNailEquipped(NailIter))
			{
				NailIter.RecallWidget.State = EContextIconState::Hidden;

				// @TODO probably not necessary
				NailIter.RecallWidget.bHasLeftEnterWiggleZone = false;
			}
			else
			{
				NailsToQuery.Add(NailIter);
			}
		}

		///////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////

		// goal: no pierced nails == no widgets
		if(WielderComp.AreAnyNailsBeingThrownOrSimulating(NailsToQuery))
		{
			// hide all nails widgets initially
			SetNailWidgetsToHidden(NailsToQuery);

			if(WielderComp.AreAnyNailsPierced(NailsToQuery))
			{
				// put a widget on the closest simulating nail if we 
				// have sweeping AND simulating nails at the same time
				TArray<ANailWeaponActor> ThrownNailsToQuery = WielderComp.GetSimulatedNails(NailsToQuery);
				if(ThrownNailsToQuery.Num() > 0 && WielderComp.AreAnyNailsSweeping(NailsToQuery))
					ThrownNailsToQuery.Append(WielderComp.GetSweepingNails(NailsToQuery));

				ANailWeaponActor ClosestNail = WielderComp.FindClosestNailInDirection(
					ThrownNailsToQuery,
					CamOrigin,
					CamDirection
				);

				// Update widget on the closest ragdolling/simulating nail
				if(ClosestNail != nullptr)
				{
					const FVector NailLocation = ClosestNail.GetActorLocation();
					const FVector TowardsNail = NailLocation - CamOrigin;
					const FVector TowardsNailNormalized = TowardsNail.GetSafeNormal();
					float CameraDot = CamDirection.DotProduct(TowardsNailNormalized);
					CameraDot = FMath::Pow(FMath::SinusoidalIn(0.f, 1.f, CameraDot), 40.f);
					ClosestNail.RecallWidget.ProgressAlpha = CameraDot;

					if(CameraDot > 0.93f)
						ClosestNail.RecallWidget.State = EContextIconState::ShowInputIcon;
					else
						ClosestNail.RecallWidget.State = EContextIconState::Visible;
				}

			}
		}
		else
		{
			// process all thrown nails
			for(ANailWeaponActor NailIter : NailsToQuery)
			{
				// set initial state for the nail widgetj
				UpdateNailWidget(NailIter, CamOrigin, CamDirection);

				// do some changes to it that are only relevant here
				if(WielderComp.IsWigglingOutOfPierce(NailIter) || WielderComp.IsNailBeingRecalled(NailIter))
					NailIter.RecallWidget.State = EContextIconState::Hidden;
				else
					NailIter.RecallWidget.State = EContextIconState::Visible;
			}

			// give 1 of the 3 widgets a specific IconState signifying that it is the closest one
			ANailWeaponActor ClosestNail = WielderComp.FindClosestNailInDirection(WielderComp.NailsThrown, CamOrigin, CamDirection);
			if(ClosestNail != nullptr)
				UpdateNailWidget(ClosestNail, CamOrigin, CamDirection);
		}
	}

	void UpdateNailWidget(
		ANailWeaponActor InNail,
		const FVector& CamOrigin,
		const FVector& CamDirection
	)
	{
		if(!IsPierced(InNail))
			return;

		if(WielderComp.IsNailBeingRecalled(InNail) && !WielderComp.IsWigglingOutOfPierce(InNail))
			return;

		const FVector NailLocation = InNail.GetActorLocation();
		const FVector TowardsNail = NailLocation - CamOrigin;
		const FVector TowardsNailNormalized = TowardsNail.GetSafeNormal();

		float CameraDot = CamDirection.DotProduct(TowardsNailNormalized);
		CameraDot = FMath::Max(0.f, CameraDot);
		CameraDot = FMath::Pow(FMath::SinusoidalIn(0.f, 1.f, CameraDot), 40.f);

		InNail.RecallWidget.ProgressAlpha = CameraDot;

		InNail.RecallWidget.State = EContextIconState::ShowInputIcon;

		// we don't want to show the icon immediately after a throw
		// but if we move away from it we'll allow the widget to pop up
		if(WielderComp.IsWigglingIntoPierce(InNail) && !InNail.RecallWidget.bHasLeftEnterWiggleZone)
		{
			// 0.99 == when the nail leaves the crosshair circumference.
			// 0.96 == crosshair diameter away from the nail, in screen space.
			if(CameraDot > 0.99f)
			{
				InNail.RecallWidget.State = EContextIconState::Hidden;
			}
			else
			{
				// We want to make sure that the widget doesn't become
				// hidden again, just because we exit the zone and then re-enter again
				InNail.RecallWidget.bHasLeftEnterWiggleZone = true;
			}
//			const float Crosshair2DToWorldRadius = TowardsNail.Size() * 0.02f;
//			System::DrawDebugSphere(NailLocation, Crosshair2DToWorldRadius);
//			PrintToScreen("Radius Threshold: " + Crosshair2DToWorldRadius);
//			PrintToScreen("CameraDot: " + CameraDot);
		}

		// hide widgets once the nail starts wiggling due to recall request
		if(WielderComp.IsWigglingOutOfPierce(InNail))
		{
			InNail.RecallWidget.State = EContextIconState::Hidden;
			InNail.RecallWidget.bHasLeftEnterWiggleZone = false;
		}

	}

	void RemoveRecallWidget(ANailWeaponActor InNail)
	{
		if(InNail.RecallWidget == nullptr)
			return;
		
		if(InNail.RecallWidget.bIsAdded == false)
			return;

//		Print("Removing widget " + InNail.GetName(), 0.f);

		Player.RemoveWidget(InNail.RecallWidget);
	}

	void AddRecallWidget(ANailWeaponActor InNail)
	{
		if(InNail.RecallWidget == nullptr)
		{
			auto CreatedWidget  = Player.AddWidget(NailRecallWidgetClass);
			InNail.RecallWidget = Cast<UNailRecallWidget>(CreatedWidget);
			InNail.RecallWidget.AttachWidgetToActor(InNail);
			InNail.RecallWidget.bHasLeftEnterWiggleZone = false;
//			Print("creating widget " + InNail.GetName(), 0.f);
		}
		else if(!InNail.RecallWidget.bIsAdded)
		{
			Player.AddExistingWidget(InNail.RecallWidget);
			InNail.RecallWidget.AttachWidgetToActor(InNail);
			InNail.RecallWidget.bHasLeftEnterWiggleZone = false;
//			Print("adding existing widget " + InNail.GetName(), 0.f);
		}
	}

	void SetNailWidgetsToHidden(const TArray<ANailWeaponActor>& InNails)
	{
		for(ANailWeaponActor NailIter : InNails)
		{
			if(NailIter.RecallWidget == nullptr)
				continue;

			if(NailIter.RecallWidget.bIsAdded == false)
				continue;

			NailIter.RecallWidget.State = EContextIconState::Hidden;
		}
	}

}