import Vino.Movement.Swinging.SwingPoint;

class UClockworkSwingPointDisableComponent : UActorComponent
{
	AClockworkSwingPoint SwingOwner;
	bool bHasDisabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingOwner = Cast<AClockworkSwingPoint>(Owner);
		SetComponentTickInterval(FMath::RandRange(0.f, 0.1f));
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Dont disable
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetComponentTickInterval(0.2f);
		if(ShouldBeDisabled() != bHasDisabled)
		{
			if(bHasDisabled)
				SwingOwner.EnableActor(this);
			else
				SwingOwner.DisableActor(this);

			bHasDisabled = !bHasDisabled;
		}
	}

	bool ShouldBeDisabled() const
	{
		if(SwingOwner.StaticMesh.WasRecentlyRendered(0.5f))
		{
			return false;
		}		
		else if(SwingOwner.PropellerMesh.WasRecentlyRendered(0.5f))
		{
			return false;
		}
		else
		{
			auto Players = Game::GetPlayers();
			for(auto Player : Players)
			{
				const float Dist = Player.GetActorLocation().DistSquared(SwingOwner.GetActorLocation());
				const float MaxDist = SwingOwner.SwingPointComponent.GetDistance(EHazeActivationPointDistanceType::Visible);
				if(Dist < FMath::Square(MaxDist))
					return false;
			}
		}

		return true;
	}
}

class AClockworkSwingPoint : ASwingPoint
{
	default DisableComponent.bAutoDisable = false;
	default DisableComponent.bRenderWhileDisabled = false;

	UPROPERTY(DefaultComponent, Attach = SwingPointComponent)
	UHazeStaticMeshComponent PropellerMesh;
	default PropellerMesh.bShouldUpdatePhysicsVolume = false;
	default PropellerMesh.bCanBeDisabled = false;

	UPROPERTY(DefaultComponent)
	UClockworkSwingPointDisableComponent DisableExtension;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat MovementCurve;

	UPROPERTY(EditDefaultsOnly)
	float MovementSpeed = 1.f / 3.f;

	// How much it will move up and down
	UPROPERTY(EditDefaultsOnly)
	float MoveHeight = 135.f;

	// How much each player will move this down form the 'MoveHeight'
	UPROPERTY(EditAnywhere)
	float WeightOffset = 70.f;

	float CurrentMovementAlpha = 0;
	int PlayersAttached = 0;
	TPerPlayer<bool> bHasBegunPlay;
	FHazeAcceleratedFloat PhysicsOffset;

	float LastUpdatedGameTime;


	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		SwingPointComponent.OnSwingPointAttached.AddUFunction(this, n"OnSwingPointAttached");
		SwingPointComponent.OnSwingPointDetached.AddUFunction(this, n"OnSwingPointDetached");
		PropellerMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PropellerMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		const float SyncValue = HasControl() ? FMath::RandRange(0.f, 1.f) : 0.f;
	
		if(Network::IsNetworked())
		{
			if(Game::GetCody().HasControl())
				NetBeginPlay(EHazePlayer::Cody, SyncValue);
			if(Game::GetMay().HasControl())
				NetBeginPlay(EHazePlayer::May, SyncValue);

			if(bHasBegunPlay[0] && bHasBegunPlay[1])
			{
				CurrentMovementAlpha += Network::GetPingRoundtripSeconds();
				LastUpdatedGameTime = Time::GetRealTimeSeconds();
			}
		}
		else
		{
			bHasBegunPlay[0] = bHasBegunPlay[1] = true;
			CurrentMovementAlpha = SyncValue;
			LastUpdatedGameTime = Time::GetRealTimeSeconds();
		}
	}

	UFUNCTION(NetFunction)
	private void NetBeginPlay(EHazePlayer Index, float SyncValue)
	{
		bHasBegunPlay[Index] = true;
		CurrentMovementAlpha += SyncValue;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float GameTime = Time::GetRealTimeSeconds();
		const float UpdateTime = GameTime - LastUpdatedGameTime;
		LastUpdatedGameTime = GameTime;

		if(PropellerMesh.WasRecentlyRendered())
			PropellerMesh.AddRelativeRotation(FRotator(0.f, 0.f, UpdateTime * 750.f));

		CurrentMovementAlpha += UpdateTime * MovementSpeed;
		CurrentMovementAlpha -= FMath::FloorToInt(CurrentMovementAlpha);

		PhysicsOffset.SpringTo(PlayersAttached * WeightOffset, 30.f, 0.1f, UpdateTime);
		
		FVector TargetRelativePosition;
		const float PlayerAttachWeightAlpha = 1.f - ((2.f - PlayersAttached) / 2.f);
		const float MoveHeightValue = FMath::Lerp(FMath::Lerp(0.f, MoveHeight, GetMoveAlpha()), MoveHeight, PlayerAttachWeightAlpha);
		TargetRelativePosition.Z += MoveHeightValue;
		
		TargetRelativePosition.Z -= PhysicsOffset.Value;
		TargetRelativePosition = FMath::VInterpTo(SwingPointComponent.RelativeLocation, TargetRelativePosition, UpdateTime, 10.f);

		SwingPointComponent.SetRelativeLocation(TargetRelativePosition);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwingPointAttached(AHazePlayerCharacter Player)
	{
		PlayersAttached++;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwingPointDetached(AHazePlayerCharacter Player)
	{
		PlayersAttached--;
	}

	float GetMoveAlpha() const
	{
		return MovementCurve.GetFloatValue(CurrentMovementAlpha);		
	}
} 