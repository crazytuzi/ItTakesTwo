import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

void JoinSnowGlobeLakeTeam(AHazeActor Member)
{
	Member.JoinTeam(n"LakeTeam", USnowGlobeLakeTeam::StaticClass());
}

void LeaveSnowGlobeLakeTeam(AHazeActor Member)
{
	Member.LeaveTeam(n"LakeTeam");
}

void SnowGlobeLakeTeamPlayerIsInWater(EHazePlayer Player, bool bStatus)
{
	auto LakeTeam = Cast<USnowGlobeLakeTeam>(HazeAIBlueprintHelper::GetTeam(n"LakeTeam"));
	if(LakeTeam != nullptr)
	{
		LakeTeam.SetPlayerInWater(Player, bStatus);
	}
}

class ASnowglobeLakeSurfaceBoarder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlaneDebugMesh;
	default PlaneDebugMesh.SetCollisionProfileName(n"NoCollision");
	default PlaneDebugMesh.SetCastShadow(false);
	default PlaneDebugMesh.bIsEditorOnly = true;
	default PlaneDebugMesh.bHiddenInGame = false;
	default PlaneDebugMesh.bVisible = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	#if EDITOR
		Billboard.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		PlaneDebugMesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// When one is valid, both are valid
		auto LakeTeam = Cast<USnowGlobeLakeTeam>(HazeAIBlueprintHelper::GetTeam(n"LakeTeam"));
		if(LakeTeam != nullptr)
		{
			for(auto Player : Game::GetPlayers())
			{
				auto SwimmingComponent = USnowGlobeSwimmingComponent::Get(Player);
				if(SwimmingComponent == nullptr)
					break;

				const float BoarderHeight = GetActorLocation().Z;
				float PlayerHeight = (Player.GetViewLocation().Z + Player.GetActorLocation().Z) / 2;
				if (SceneView::IsFullScreen())
				{
					auto FullScreenPlayer = SceneView::FullScreenPlayer;
					PlayerHeight = FullScreenPlayer.GetViewLocation().Z;	
				}

				const bool bUnderSurface = PlayerHeight < BoarderHeight;
				LakeTeam.SetPlayerUnderSurface(Player.Player, bUnderSurface);
			}
		}
	}
}

class USnowGlobeLakeTeam : UHazeAITeam
{
	private TPerPlayer<bool> bPlayersInWater;
	private TPerPlayer<bool> bPlayersUnderSurface;

	void SetPlayerUnderSurface(EHazePlayer Player, bool bStatus)
	{
		if(bPlayersUnderSurface[Player] == bStatus)
			return;

		bPlayersUnderSurface[Player] = bStatus;
		auto CurrentMembers = GetMembers();
		for (auto Member : CurrentMembers)
		{	
			SetPlayersUnderSurfaceInternal(Member, bStatus);
		}
	}

	void SetPlayerInWater(EHazePlayer Player, bool bStatus)
	{
		if(bPlayersInWater[Player] == bStatus)
			return;

		bPlayersInWater[Player] = bStatus;
		auto CurrentMembers = GetMembers();
		for (auto Member : CurrentMembers)
		{			
			SetPlayersInWaterInternal(Member, bStatus);
		}
	}

	private void SetPlayersUnderSurfaceInternal(AHazeActor Member, bool bStatus)
	{
		auto UnderwaterDisable = USnowGlobeLakeDisableComponentExtension::Get(Member);
		if(UnderwaterDisable != nullptr)
		{
			if(bStatus)
				UnderwaterDisable.IncreasePlayersUnderSurface();
			else
				UnderwaterDisable.DecreasePlayersUnderSurface();
		}
	}

	private void SetPlayersInWaterInternal(AHazeActor Member, bool bStatus)
	{
		auto UnderwaterDisable = USnowGlobeLakeDisableComponentExtension::Get(Member);
		if(UnderwaterDisable != nullptr)
		{
			if(bStatus)
				UnderwaterDisable.IncreasePlayersInWater();
			else
				UnderwaterDisable.DecreasePlayersInWater();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		for(int i = 0; i < 2; ++i)
		{
			if(bPlayersUnderSurface[i])
				SetPlayersUnderSurfaceInternal(Member, true);

			if(bPlayersInWater[i])
				SetPlayersInWaterInternal(Member, true);	
		}
	}
}