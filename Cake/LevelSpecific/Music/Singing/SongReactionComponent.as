import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeInfo;
import Cake.LevelSpecific.Music.Singing.SingingSettings;
import Vino.ActivationPoint.ActivationPointStatics;
import Cake.LevelSpecific.Music.MusicImpactComponent;

import bool IsPowerfulSongOnCooldown(AActor) from "Cake.LevelSpecific.Music.Singing.SingingComponent";

class USongReactionContainerComponent : UActorComponent
{
	TArray<USongReactionComponent> ListOfSongReactions;
}

class USongReactionComponent : UMusicImpactComponent
{
	default BiggestDistanceType = EHazeActivationPointDistanceType::Targetable;
	default ValidationIdentifier = EHazeActivationPointIdentifierType::LevelSpecific;
	default ValidationType = EHazeActivationPointActivatorType::May;

	default WidgetClass = Asset("/Game/Blueprints/LevelSpecific/Music/Singing/PowerfulSong/WBP_PowerfulSongWidget.WBP_PowerfulSongWidget_C");

	// Return true if both Song of life and powerful song are enabled.
	UFUNCTION(BlueprintPure)
	bool AreSongReactionsEnabled() const { return bPowerfulSongEnabled; }

	private bool bAffectedBySongOfLife = false;
	// Returns true if Song of life is currently affecting this Actor.
	UFUNCTION(BlueprintPure, meta = (DeprecatedFunction))
	bool IsAffectedBySongOfLife() const { return bAffectedBySongOfLife; }

	private bool bPowerfulSongEnabled = true;
	private bool bSongOfLifeEnabled = true;

	UPROPERTY()
	FOnPowerfulSongImpact OnPowerfulSongImpact;

	//default bRequireAiming = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USongReactionContainerComponent ReactionContainer = USongReactionContainerComponent::GetOrCreate(Game::GetMay());

		if(ReactionContainer.ListOfSongReactions.Num() == 0)
			Reset::RegisterPersistentComponent(ReactionContainer);

		ReactionContainer.ListOfSongReactions.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		USongReactionContainerComponent ReactionContainer = USongReactionContainerComponent::GetOrCreate(Game::GetMay());
		bool bHadReactions = ReactionContainer.ListOfSongReactions.Num() != 0;
		ReactionContainer.ListOfSongReactions.Remove(this);

		if (bHadReactions && ReactionContainer.ListOfSongReactions.Num() == 0)
			Reset::UnregisterPersistentComponent(ReactionContainer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const override
	{	
		if(!AreSongReactionsEnabled())
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		if(IsPowerfulSongOnCooldown(Player))
		{
			return EHazeActivationPointStatusType::InvalidAndHidden;
		}

		return Super::SetupActivationStatus(Player, Query);
	}

	UFUNCTION(BlueprintOverride)
	float SetupGetDistanceForPlayer(AHazePlayerCharacter Player, EHazeActivationPointDistanceType Type) const
	{
		USingingSettings SingingSettings = USingingSettings::GetSettings(Player);

		if(SingingSettings == nullptr)
			return GetDistance(Type);

		if(Type == EHazeActivationPointDistanceType::Selectable)
			return SingingSettings.SingingRange;
		else if(Type == EHazeActivationPointDistanceType::Targetable)
			return SingingSettings.SingingRange;
		else if(Type == EHazeActivationPointDistanceType::Visible)
			return SingingSettings.SingingRangeVisible;

		return GetDistance(Type);
	}

	UFUNCTION()
	void SetSongReactionsEnabled(bool bValue)
	{
		bPowerfulSongEnabled = bValue;
	}

	UFUNCTION()
	void SetPowerfulSongEnabled(bool bValue)
	{
		bPowerfulSongEnabled = bValue;
	}

	UFUNCTION()
	void SetSongOfLifeEnabled(bool bValue)
	{
		bSongOfLifeEnabled = bValue;
	}

	UFUNCTION(BlueprintPure)
	bool IsPowerfulSongEnabled() const { return bPowerfulSongEnabled; }
	UFUNCTION(BlueprintPure, meta = (Deprecated))
	bool IsSongOfLifeEnabled() const { return bSongOfLifeEnabled; }

	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		if(!bPowerfulSongEnabled)
			return;

		OnPowerfulSongImpact.Broadcast(Info);
	}

	UFUNCTION(NetFunction)
	void NetPowerfulSongImpact(FPowerfulSongInfo Info)
	{
		if(!bPowerfulSongEnabled)
			return;
		
		OnPowerfulSongImpact.Broadcast(Info);
	}
}
