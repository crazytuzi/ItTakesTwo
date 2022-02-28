
import void JoinSnowGlobeLakeTeam(AHazeActor Member) from "Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeTeam";
import void LeaveSnowGlobeLakeTeam(AHazeActor Member) from "Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeTeam";

enum ESnowGlobeLakeDisableType
{
	ActiveOnSurface,
	ActiveUnderSurfaceAlways,
	ActiveUnderSurfaceInWater,
	ActiveInWaterOrUnderSurface,
}

class USnowGlobeLakeDisableComponentExtension : USceneComponent
{	
	default bVisible = false;

	UPROPERTY(Category = "Disabling")
	ESnowGlobeLakeDisableType ActiveType = ESnowGlobeLakeDisableType::ActiveOnSurface;
	
	UPROPERTY(Category = "Disabling")
	FHazeMinMax DisableRange = FHazeMinMax(2000.f, 10000.f);

	UPROPERTY(Category = "Disabling")
	float ViewRadius = 900.f;

	UPROPERTY(Category = "Disabling")
	float DontDisableWhileVisibleTime = 0.1f;

	UPROPERTY(Category = "Disabling")
	bool bActorIsVisualOnly = false;

	UPROPERTY(Category = "Disabling")
	float TickDelay = 1.f;

	UPROPERTY(EditConst)
	UBoxComponent BoxVisualizer;

	UPROPERTY(EditConst)
	USphereComponent SphereVisualizer;

	private AHazeActor HazeOwner;
	private USkeletalMeshComponent Mesh;
	private UHazeDisableComponent ParentDisableComponent;

	private bool bIsDisabledBySurface = false;
	private bool bIsAutoDisabled = false;
	
	const int MAX_AMOUNT = 2;
	private int PlayersUnderSurfaceCount = 0;
	private int PlayersInWaterCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		ParentDisableComponent = UHazeDisableComponent::Get(HazeOwner);
		ensure(ParentDisableComponent != nullptr); // We must have a disable component

		// Setup the mesh
		auto CharacterOwner = Cast<AHazeCharacter>(Owner);
		if(CharacterOwner != nullptr)
			Mesh = CharacterOwner.Mesh;
		else
			Mesh = USkeletalMeshComponent::Get(HazeOwner);

		JoinSnowGlobeLakeTeam(HazeOwner);
		SetComponentTickInterval(FMath::RandRange(0.f, TickDelay * 0.5f));
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveSnowGlobeLakeTeam(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Never disable
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SetComponentTickInterval(TickDelay);
		if(bActorIsVisualOnly || HasControl())
		{
			const bool bWantsToBeDisabled = ShouldBeDisabled();
			if(bWantsToBeDisabled != bIsDisabledBySurface)
			{
				bIsDisabledBySurface = bWantsToBeDisabled;
				SetActorDisabled(bWantsToBeDisabled, n"SurfaceType");
			}

			const bool bShouldBeAutoDisabled = ShouldAutoDisable();
			if(bIsAutoDisabled != bShouldBeAutoDisabled)
			{
				bIsAutoDisabled = bShouldBeAutoDisabled;
				SetActorDisabled(bIsAutoDisabled, n"AutoDisable");
			}
		}
	}

	void IncreasePlayersUnderSurface()
	{
		PlayersUnderSurfaceCount += 1;
	}

	void DecreasePlayersUnderSurface()
	{
		PlayersUnderSurfaceCount -= 1;
	}

	void IncreasePlayersInWater()
	{
		PlayersInWaterCount += 1;
	}

	void DecreasePlayersInWater()
	{
		PlayersInWaterCount -= 1;
	}

	private bool ShouldBeDisabled() const
	{
		if(ActiveType == ESnowGlobeLakeDisableType::ActiveOnSurface)
		{
			return PlayersUnderSurfaceCount == MAX_AMOUNT;
		}
		else 
		{
			if(PlayersUnderSurfaceCount == 0 && PlayersInWaterCount == 0)
				return true;
			
			if(ActiveType == ESnowGlobeLakeDisableType::ActiveUnderSurfaceAlways)
			{
				return PlayersUnderSurfaceCount == 0;
			}
			else if(ActiveType == ESnowGlobeLakeDisableType::ActiveUnderSurfaceInWater)
			{
				if(PlayersUnderSurfaceCount == 0)
					return true;
				return PlayersInWaterCount == 0;
			}
			else if(ActiveType == ESnowGlobeLakeDisableType::ActiveInWaterOrUnderSurface)
			{
				return false;
			}
		}

		return true;
	}

	private bool ShouldAutoDisable() const
	{
		float ClosestPlayerDistSq = BIG_NUMBER;
		for(auto Player : Game::GetPlayers())
		{
			if (SceneView::IsFullScreen())
			{
				auto FullScreenPlayer = SceneView::FullScreenPlayer;
				const float Dist = FullScreenPlayer.GetActorLocation().DistSquared(GetWorldLocation());
				if(Dist < ClosestPlayerDistSq)
					ClosestPlayerDistSq = Dist * 0.25f;
			}
			else
			{
				const float Dist = Player.GetActorLocation().DistSquared(GetWorldLocation());
				if(Dist < ClosestPlayerDistSq)
					ClosestPlayerDistSq = Dist;
			}

		}

		if(ClosestPlayerDistSq < FMath::Square(DisableRange.Min))
			return false;

		if(ClosestPlayerDistSq > FMath::Square(DisableRange.Max))
			return true;
			
		if(Mesh != nullptr && Mesh.WasRecentlyRendered(DontDisableWhileVisibleTime))
			return false;

		for(auto Player : Game::GetPlayers())
		{
			if(BoxVisualizer == nullptr && SphereVisualizer == nullptr)
			{
				if(SceneView::ViewFrustumPointRadiusIntersection(Player, GetWorldLocation(), ViewRadius))
					return false;
			}
			else
			{
				if(BoxVisualizer != nullptr)
				{
					if(SceneView::ViewFrustumBoxIntersection(Player, BoxVisualizer))
						return false;
				}

				if(SphereVisualizer != nullptr)
				{
					if(SceneView::ViewFrustumSphereIntersection(Player, SphereVisualizer))
						return false;
				}
			}
		}

		return true;
	}

	private void SetActorDisabled(bool bStatus, FName Tag)
	{
		if(bActorIsVisualOnly || !Network::IsNetworked())
			SetActorDisabledInternal(bStatus, Tag);
		else if(HasControl())
			NetSetActorDisabled(bStatus, Tag);
	}

	UFUNCTION(NetFunction)
	private void NetSetActorDisabled(bool bStatus, FName Tag)
	{
		SetActorDisabledInternal(bStatus, Tag);
	}

	private void SetActorDisabledInternal(bool bStatus, FName Tag)
	{
		if(bStatus)
			HazeOwner.DisableActor(this, Tag);
		else
			HazeOwner.EnableActor(this, Tag);
	}
}
