import Cake.LevelSpecific.Music.MusicTargetingWidget;
import Peanuts.Aiming.AutoAimStatics;
import Cake.LevelSpecific.Music.MusicImpactComponent;

bool IsAiming(AActor Owner)
{
	UMusicTargetingComponent MusicTargetingComponent = UMusicTargetingComponent::Get(Owner);

	if(MusicTargetingComponent != nullptr)
	{
		return MusicTargetingComponent.bIsTargeting;
	}

	return false;
}

bool MusicTargetingTrace(AHazePlayerCharacter Player, const UMusicImpactComponent ImpactComponent, FHazeHitResult& OutResult)
{
	// Invalid
	if(ImpactComponent == nullptr)
		return false;

	// Invalid
	auto TargetingComp = UMusicTargetingComponent::Get(Player);
	if(TargetingComp == nullptr)
		return false;
	
	// Auto aim trace override the regular trace
	auto AutoAimComp = UAutoAimTargetComponent::Get(ImpactComponent.Owner);
	if(AutoAimComp != nullptr && AutoAimComp.PlayerCanTarget(Player))
	{
		if(TargetingComp.AutoAimTrace.AutoAimedAtActor == ImpactComponent.Owner)
		{
			FVector ImpactPoint = ImpactComponent.GetTransformFor(Player).Location;
			FVector DirToPoint = (ImpactPoint - TargetingComp.GetTraceStartPoint()).GetSafeNormal();
			OutResult.OverrideFHitResult(FHitResult(ImpactComponent.Owner, nullptr, ImpactPoint, DirToPoint));
			return true;
		}
		
		// Already valid
		if(TargetingComp.ImpactTrace.Actor == ImpactComponent.Owner)
		{
			OutResult = TargetingComp.ImpactTrace;
			return true;
		}

		return false;
	}

	// Already valid
	if(TargetingComp.ImpactTrace.Actor == ImpactComponent.Owner)
	{
		OutResult = TargetingComp.ImpactTrace;
		return true;
	}

	const FVector TraceFrom = TargetingComp.GetTraceStartPoint();

	bool bDebug = false;
#if EDITOR
	bDebug = ImpactComponent.bHazeEditorOnlyDebugBool;
#endif

	// we store the current trace to the object
	FVector TraceTo = ImpactComponent.GetTransformFor(Player).Location;
	TraceTo += (TraceTo - TraceFrom).GetSafeNormal() * 25.f; // safeyty amount so we hit the shape
	TargetingComp.GetImpactTrace(TraceFrom, TraceTo, OutResult, bDebug);
	if(OutResult.Actor != ImpactComponent.Owner)
		return false;

	return true;
}

UCLASS(Abstract)
class UMusicTargetingComponent : UActorComponent
{
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());

		TargetingWidgetInstance = Cast<UMusicTargetingWidget>(Player.AddWidget(TargetingWidgetClass));
		TargetingWidgetInstance.SetVisibility(ESlateVisibility::Collapsed);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Player.RemoveWidgetFromHUD(TargetingWidgetInstance);
		TargetingWidgetInstance = nullptr;
	}

	private FMusicHitResult CurrentMusicHit;
	private TArray<AActor> ActorsToIgnore;
	
	UPROPERTY(Category = UI)
	TSubclassOf<UMusicTargetingWidget> TargetingWidgetClass;
	UMusicTargetingWidget TargetingWidgetInstance = nullptr;

	UPROPERTY(Category = Collision)
	ETraceTypeQuery ImpactTraceType;
	default ImpactTraceType = ETraceTypeQuery::Visibility;

	FAutoAimLine AutoAimTrace;
	FHazeHitResult ImpactTrace;

	bool HasValidTarget() const { return bHasValidTarget; }
	UMusicImpactComponent GetCurrentTarget() const property
	{
		return CurrentMusicHit.ImpactComponent;
	}

	void UpdateWidgetOffset(FVector InWidgetOffset)
	{
		FVector2D Offset;
		Offset.X = InWidgetOffset.X;
		Offset.Y = InWidgetOffset.Y;
		UpdateWidgetOffset(Offset);
	}

	void UpdateWidgetOffset(FVector2D InWidgetOffset)
	{
		if(TargetingWidgetInstance == nullptr)
			return;

		TargetingWidgetInstance.BP_OnUpdateWidgetOffset(InWidgetOffset);
	}

	bool bIsTargeting = false;
	bool bHasValidTarget = false;

	void GetImpactTrace(FVector From, FVector To, FHazeHitResult& OutResult, bool bWithDebug) const
	{
		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(ImpactTraceType);
		Trace.IgnoreActors(ActorsToIgnore);
		Trace.From = From;
		Trace.To = To;
		Trace.DebugDrawTime = bWithDebug ? 0.f : -1.f;
		Trace.SetToLineTrace();

		Trace.Trace(OutResult);
	}

	void UpdateImpactHitResult(AHazePlayerCharacter Player, UMusicImpactComponent Component, FHazeHitResult MusicHit)
	{
		UMusicImpactComponent OldImpact = CurrentMusicHit.ImpactComponent;
		CurrentMusicHit = FMusicHitResult(Player, Component, MusicHit);
		if(!CurrentMusicHit.IsValid())
		{
			bHasValidTarget = false;
			TargetingWidgetInstance.SetHasTarget(false);
		}
		else
		{
			if(OldImpact != nullptr && OldImpact != Component)
			{
				TargetingWidgetInstance.BP_OnTargetLost();
				TargetingWidgetInstance.BP_OnTargetFound();
			}
			bHasValidTarget = true;
			TargetingWidgetInstance.SetHasTarget(true);
			CurrentMusicHit.UpdateImpactPoint(MusicHit.ImpactPoint);
			TargetingWidgetInstance.SetTargetLocation(Component.WorldLocation);
		}
	}

	FVector GetTraceStartPoint() const
	{
		FVector TraceFrom = Player.ViewLocation;
		TraceFrom += Player.ViewRotation.ForwardVector * TraceFrom.Dist2D(Player.GetActorLocation(), Player.GetMovementWorldUp());
		return TraceFrom;
	}

	void StartTargeting()
	{
		TargetingWidgetInstance.SetVisibility(ESlateVisibility::Visible);
		TargetingWidgetInstance.BP_OnStartAiming();
	}

	void StopTargeting()
	{
		TargetingWidgetInstance.BP_OnStopAiming();
		TargetingWidgetInstance.SetVisibility(ESlateVisibility::Collapsed);
	}

	void UpdateAimWidgetLocation(FVector InTargetLocation)
	{
		TargetingWidgetInstance.SetTargetLocation(InTargetLocation);
	}

	void UpdateAimWidgetHasTarget(bool bValue)
	{
		TargetingWidgetInstance.SetHasTarget(bValue);
	}
}
