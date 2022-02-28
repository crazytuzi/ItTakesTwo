import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

class USingingDebugCapability : UHazeDebugCapability
{
	USingingComponent SingingComp;
	USongReactionContainerComponent ContainerComp;
	USongOfLifeContainerComponent SongOfLifeContainer;
	USingingSettings Settings;

	private bool bDrawDebug = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SingingComp = USingingComponent::Get(Owner);
		ContainerComp = USongReactionContainerComponent::GetOrCreate(Owner);
		SongOfLifeContainer = USongOfLifeContainerComponent::GetOrCreate(Owner);
		Settings = USingingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		FHazeDebugFunctionCallHandler TogleInfiniteSongOfLifeHandler = DebugValues.AddFunctionCall(n"ToggleInfiniteSongOfLife", "Toggle Infinite Song Of Life");
		FHazeDebugFunctionCallHandler TogleDrawDebugHandler = DebugValues.AddFunctionCall(n"ToggleDrawDebug", "Toggle Draw Debug");

		TogleInfiniteSongOfLifeHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadLeft, n"Singing");
		TogleDrawDebugHandler.AddActiveUserButton(EHazeDebugActiveUserCategoryButtonType::DPadDown, n"Singing");
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
		System::DrawDebugSphere(Owner.ActorCenterLocation, Settings.SongOfLifeRange, 16, FLinearColor::DPink, 0, 10);

		for(USongReactionComponent SongReaction : ContainerComp.ListOfSongReactions)
		{
			if(SongReaction == nullptr)
				continue;
			if(SongReaction.IsBeingDestroyed())
				continue;

			FVector Origin, BoxExtent;
			SongReaction.Owner.GetActorBounds(false, Origin, BoxExtent);
			FLinearColor Color = FLinearColor::Yellow;

			System::DrawDebugBox(Origin, BoxExtent, Color, FRotator::ZeroRotator, 0, 10);
		}

		for(USongOfLifeComponent SongComp : SongOfLifeContainer.SongOfLifeCollection)
		{
			if(SongComp == nullptr)
				continue;
			if(SongComp.IsBeingDestroyed())
				continue;

			FVector Origin, BoxExtent;
			SongComp.Owner.GetActorBounds(false, Origin, BoxExtent);
			FLinearColor Color = SongComp.bSongOfLifeInRange ? FLinearColor::Green : FLinearColor::Red;

			if(SongComp.IsAffectedBySongOfLife())
				Color = FLinearColor::Purple;

			System::DrawDebugBox(Origin, BoxExtent, Color, FRotator::ZeroRotator, 0, 10);
		}

		for(APowerfulSongProjectile Projectile : SingingComp.ActivePowerfulSongProjectiles)
		{
			System::DrawDebugLine(Projectile.StartLocation, Projectile.ActorCenterLocation, FLinearColor::Green, 0, 10);

			if(Projectile.TargetActor != nullptr)
			{
				FVector Origin, Extents;
				Projectile.TargetActor.GetActorBounds(true, Origin, Extents);
				System::DrawDebugBox(Origin, Extents * 1.1f, FLinearColor::Red, FRotator::ZeroRotator, 0, 10);
			}
		}

		for(APowerfulSongProjectile Projectile : SingingComp.AllProjectiles)
		{
			Projectile.DrawDebugHits();

		}
	}

	UFUNCTION()
	private void ToggleInfiniteSongOfLife()
	{
		SingingComp.bInfiniteSongOfLife = !SingingComp.bInfiniteSongOfLife;
	}

	UFUNCTION()
	private void ToggleDrawDebug()
	{
		bDrawDebug = !bDrawDebug;
	}
}
