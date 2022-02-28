import Cake.LevelSpecific.Music.KeyBird.KeyBird;
import Cake.LevelSpecific.Music.KeyBird.KeyBirdBehaviorComponent;

class UKeyBirdDebugCapability : UHazeDebugCapability
{
	bool bDrawKeyHolders = false;
	bool bDrawBehavior = false;
	bool bCanStealKey = true;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler KillOneKeyHolderHandler = DebugValues.AddFunctionCall(n"KillOneKeyHolder", "Kill One KeyHolder");
		FHazeDebugFunctionCallHandler KillAllKeyBirds = DebugValues.AddFunctionCall(n"KillAllKeyBirds", "Kill All KeyBirds");
		FHazeDebugFunctionCallHandler ToggleDrawDebugKeyHoldersHandler = DebugValues.AddFunctionCall(n"ToggleDrawDebugKeyHolders", "Draw Key Holders");
		FHazeDebugFunctionCallHandler ToggleDrawBehaviorHandler = DebugValues.AddFunctionCall(n"ToggleDrawBehavior", "Draw Key Bird Behavior");
		FHazeDebugFunctionCallHandler ToggleCanStealKey = DebugValues.AddFunctionCall(n"ToggleCanStealKey", "Toggle Can Steal Key");

		KillOneKeyHolderHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"KeyBird");
		ToggleDrawDebugKeyHoldersHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"KeyBird");
		KillAllKeyBirds.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadUp, n"KeyBird");
		ToggleDrawBehaviorHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadRight, n"KeyBird");
		ToggleCanStealKey.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::TriggerRight, n"KeyBird");
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
		if(bDrawKeyHolders)
			DrawKeyHolders();

		if(bDrawBehavior)
			DrawBehavior();

		if(!bCanStealKey)
			PrintToScreen("Steal Key Disabled");
	}

	private void DrawKeyHolders()
	{
		UHazeAITeam KeyBirdTeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(KeyBirdTeam == nullptr)
			return;

		TSet<AHazeActor> Members = KeyBirdTeam.Members;

		for(AHazeActor KeyBirdActor : Members)
		{
			AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

			if(KeyBird == nullptr)
				continue;

			if(!KeyBird.HasKey())
				continue;

			if(KeyBird.IsDead())
				continue;

			FVector Extent, Origin;
			KeyBird.GetActorBounds(false, Origin, Extent);
			System::DrawDebugBox(Origin, Extent * 1.5f, FLinearColor::MakeRandomColor(), FRotator::ZeroRotator, 0, 30);
			PrintToScreen("KeyBird KeyHolderName: " + KeyBird.Name + " - NumKeys: " + KeyBird.NumKeys());
		}
	}

	private void DrawBehavior()
	{
		UHazeAITeam KeyBirdTeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(KeyBirdTeam == nullptr)
			return;

		TSet<AHazeActor> Members = KeyBirdTeam.Members;

		int NumRandomMovement = 0;
		int NumStealKey = 0;
		int NumSeekKey = 0;
		int NumDisabled = 0;

		for(AHazeActor KeyBirdActor : Members)
		{
			AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);
			UKeyBirdBehaviorComponent BehaviorComp = UKeyBirdBehaviorComponent::Get(KeyBirdActor);
			USteeringBehaviorComponent Steering = USteeringBehaviorComponent::Get(KeyBirdActor);

			if(KeyBird == nullptr)
				continue;

			if(KeyBird.IsDead())
				continue;

			if(!KeyBird.IsKeyBirdEnabled())
			{
				NumDisabled++;
				continue;
			}

			if(BehaviorComp == nullptr)
				continue;

			const float KeyBirdRadius = 400.0f;
			const float PlayerRadius = 300.0f;
			const float Thickness = 6.0f;

			if(BehaviorComp.CurrentState == EKeyBirdState::RandomMovement)
			{
				NumRandomMovement++;
			}
			else if(BehaviorComp.CurrentState == EKeyBirdState::SeekKey)
			{
				NumSeekKey++;
				System::DrawDebugSphere(KeyBirdActor.ActorLocation, KeyBirdRadius, 12, FLinearColor::Blue, 0.0f, Thickness);
				System::DrawDebugLine(KeyBirdActor.ActorLocation, Steering.Seek.SeekLocation, FLinearColor::DPink, 0.0f, Thickness);
				System::DrawDebugSphere(Steering.Seek.SeekLocation, PlayerRadius, 12, FLinearColor::Red, 0.0f, Thickness);
			}
			else if(BehaviorComp.CurrentState == EKeyBirdState::StealKey)
			{
				NumStealKey++;
				System::DrawDebugSphere(KeyBirdActor.ActorLocation, KeyBirdRadius, 12, FLinearColor::Blue, 0.0f, Thickness);
				System::DrawDebugLine(KeyBirdActor.ActorLocation, Steering.Seek.SeekLocation, FLinearColor::DPink, 0.0f, Thickness);
				System::DrawDebugSphere(Steering.Seek.SeekLocation, PlayerRadius, 12, FLinearColor::Red, 0.0f, Thickness);
			}
			else if(BehaviorComp.CurrentState == EKeyBirdState::SplineMovement && KeyBird.CurrentSplineActor != nullptr)
			{
				const FVector SplineLocationCurrent = KeyBird.CurrentSplineActor.Spline.GetLocationAtDistanceAlongSpline(KeyBird.SplineDistanceCurrent, ESplineCoordinateSpace::World);
				System::DrawDebugSphere(SplineLocationCurrent, 200.0f, 12, FLinearColor::Green);
				System::DrawDebugLine(SplineLocationCurrent, KeyBird.ActorCenterLocation, FLinearColor::Blue, 0, 10.0f);
			}
		}

		PrintToScreen("Disabled: " + NumDisabled);
		PrintToScreen("SeekKey: " + NumSeekKey);
		PrintToScreen("StealKey: " + NumStealKey);
		PrintToScreen("RandomMovement: " + NumRandomMovement);
	}

	UFUNCTION()
	private void ToggleCanStealKey()
	{
		bCanStealKey = !bCanStealKey;

		TArray<AActor> ListOfAreas;
		Gameplay::GetAllActorsOfClass(AKeyBirdCombatArea::StaticClass(), ListOfAreas);

		for(AActor CombatAreaActor : ListOfAreas)
		{
			AKeyBirdCombatArea CombatArea = Cast<AKeyBirdCombatArea>(CombatAreaActor);
			if(CombatArea != nullptr)
			{
				CombatArea.bCanStealKey = bCanStealKey;
			}
		}
	}

	UFUNCTION()
	private void KillOneKeyHolder()
	{
		if(!HasControl())
			return;

		UHazeAITeam KeyBirdTeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(KeyBirdTeam == nullptr)
			return;

		TSet<AHazeActor> Members = KeyBirdTeam.Members;

		for(AHazeActor KeyBirdActor : Members)
		{
			AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

			if(KeyBird == nullptr)
				continue;

			if(!KeyBird.HasKey())
				continue;

			if(KeyBird.IsDead())
				continue;

			if(!KeyBird.IsKeyBirdEnabled())
				continue;

			NetDestroyKeyBird(KeyBird);

			break;
		}
	}

	UFUNCTION()
	private void KillAllKeyBirds()
	{
		if(!_KillAllKeyBirds(Game::GetMay()))
			_KillAllKeyBirds(Game::GetCody());
	}

	private bool _KillAllKeyBirds(AHazePlayerCharacter PlayerInstigator)
	{
		ABoidArea CombatArea = FindClosestBoidArea(PlayerInstigator.ActorLocation);

		if(CombatArea == nullptr)
			return false;
		
		UHazeAITeam KeyBirdTeam = HazeAIBlueprintHelper::GetTeam(n"KeyBirdTeam");

		if(KeyBirdTeam == nullptr)
			return false;

		TSet<AHazeActor> Members = KeyBirdTeam.Members;
		TArray<AKeyBird> KeyBirdsToDestroy;

		for(AHazeActor KeyBirdActor : Members)
		{
			AKeyBird KeyBird = Cast<AKeyBird>(KeyBirdActor);

			if(KeyBird == nullptr)
				continue;

			if(!KeyBird.IsKeyBirdEnabled())
				continue;

			if(KeyBird.IsDead())
				continue;

			if(KeyBird.CombatArea == nullptr || KeyBird.CombatArea == CombatArea)
				KeyBirdsToDestroy.Add(KeyBird);
		}

		if(KeyBirdsToDestroy.Num() > 0)
			NetDestroyAllKeyBirds(KeyBirdsToDestroy, PlayerInstigator);

		return KeyBirdsToDestroy.Num() > 0;
	}

	UFUNCTION(NetFunction)
	private void NetDestroyAllKeyBirds(TArray<AKeyBird> KeyBirdsToDestroy, AHazePlayerCharacter InstigatorPlayer)
	{
		for(AKeyBird KeyBird : KeyBirdsToDestroy)
		{
			KeyBird.DestroyActorFunction(InstigatorPlayer, FVector::ForwardVector);
		}
	}

	UFUNCTION(NetFunction)
	private void NetDestroyKeyBird(AKeyBird KeyBirdToDestroy)
	{
		if(KeyBirdToDestroy != nullptr)
			KeyBirdToDestroy.DestroyActorFunction(Game::GetMay(), FVector::ForwardVector);
	}

	UFUNCTION()
	private void ToggleDrawDebugKeyHolders()
	{
		bDrawKeyHolders = !bDrawKeyHolders;
	}

	UFUNCTION()
	private void ToggleDrawBehavior()
	{
		bDrawBehavior = !bDrawBehavior;
	}
}
