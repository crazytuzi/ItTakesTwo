import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophonePlayerComponent;

import bool ShouldEnterHypnosis(AActor) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone";
import bool IsInHypnosis(AActor) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone";
import bool IsLocationInsideChaseRange(AActor, FVector) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone";
import bool IsLocationInsideAggressiveRange(AActor, FVector) from "Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone";

#if EDITOR

class UMurderMicrophoneTargetingVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UMurderMicrophoneTargetingComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UMurderMicrophoneTargetingComponent Comp = Cast<UMurderMicrophoneTargetingComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;

		if(!Comp.bEnableVisionVisualizer)
			return;

		const FVector Origin = Comp.Owner.ActorLocation;

		DrawWireSphere(Origin, Comp.ChaseRange, FLinearColor::Blue, 6.0f);
		DrawWireSphere(Origin, Comp.AggressiveRange, FLinearColor::Red, 6.0f);
		DrawWireSphere(Origin, Comp.VisionRange, FLinearColor::Purple, 6.0f);
	}
}

#endif // EDITOR

struct FMurderMicrophoneTargetInfo
{
	AHazePlayerCharacter Player;
	float DistanceSq = 0.0f;
	bool bChaseRange = false;
	bool bAggressiveRange = false;
	bool bVisionRange = false;
	bool bHasSight = false;
}

class UMurderMicrophoneTargetingComponent : UActorComponent
{
#if !TEST
	default PrimaryComponentTick.bStartWithTickEnabled = false;
#else
	default PrimaryComponentTick.bStartWithTickEnabled = true;
#endif // !TEST

	private UHazeAsyncTraceComponent AsyncTrace = nullptr;

	// Player will be noticed by snake.
	UPROPERTY()
	float VisionRange = 5000.0f;

	// Chase player until this range is reached.
	UPROPERTY()
	float ChaseRange = 4000.0f;

	// Snake will approach player and attempt to eat.
	UPROPERTY()
	float AggressiveRange = 3000.0f;

	UPROPERTY()
	bool bTraceVisibility = true;

	// Use DistSquared2D for distance checks and ignore height.
	UPROPERTY()
	bool bTargetOnly2D = false;

	// Enable or disable the visualizer drawing vision spheres in the editor only.
	UPROPERTY(Category = Debug)
	bool bEnableVisionVisualizer = true;

	private FMurderMicrophoneTargetInfo CodyTargetInfo;
	private FMurderMicrophoneTargetInfo MayTargetInfo;
	private bool bIsTracingToCody = false;
	private bool bIsTracingToMay = false;
	private TArray<AActor> _AdditionalIgnoreActors;

	void AddIgnoreActor(AActor NewIgnoreActor)
	{
		_AdditionalIgnoreActors.AddUnique(NewIgnoreActor);
	}

	UPROPERTY()
	bool bIgnorePlayer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AsyncTrace = UHazeAsyncTraceComponent::Get(Owner);

		MayTargetInfo.Player = Game::GetMay();
		CodyTargetInfo.Player = Game::GetCody();
	}

	float GetAggressiveRangeSq() const property { return FMath::Square(AggressiveRange); }
	float GetChaseRangeSq() const property { return FMath::Square(ChaseRange); }
	float GetVisionRangeSq() const property { return FMath::Square(VisionRange); }

	void UpdateVisibility(FVector EyesLocation)
	{
		//PrintToScreen("May Sight " + MayTargetInfo.bHasSight);

		if(bIgnorePlayer)
			return;

		AHazePlayerCharacter Cody = Game::GetCody();
		AHazePlayerCharacter May = Game::GetMay();

		bool bIgnoreMay = false;

		const FVector Origin = Owner.ActorLocation;
		const FVector CodyLocation = Cody.ActorCenterLocation;
		const FVector MayLocation = May.ActorCenterLocation;

		const float CodyDistSq = bTargetOnly2D ? CodyLocation.DistSquared2D(Origin) : CodyLocation.DistSquared(Origin);
		const float MayDistSq = bTargetOnly2D ? MayLocation.DistSquared2D(Origin) : MayLocation.DistSquared(Origin);
		
		CodyTargetInfo.DistanceSq = CodyDistSq;
		CodyTargetInfo.bVisionRange = CodyDistSq < VisionRangeSq;
		CodyTargetInfo.bAggressiveRange = IsLocationInsideAggressiveRange(Owner, CodyLocation);
		CodyTargetInfo.bChaseRange = IsLocationInsideChaseRange(Owner, CodyLocation);

		MayTargetInfo.DistanceSq = MayDistSq;
		MayTargetInfo.bVisionRange = MayDistSq < VisionRangeSq;
		MayTargetInfo.bAggressiveRange = IsLocationInsideAggressiveRange(Owner, MayLocation);
		MayTargetInfo.bChaseRange = IsLocationInsideChaseRange(Owner, MayLocation);

		if(Cody.IsPlayerDead())
			SetTargetInvalid(CodyTargetInfo);

		if(May.IsPlayerDead())
			SetTargetInvalid(MayTargetInfo);

		if(IsTargetBeingEatenBySnake(May))
			SetTargetInvalid(MayTargetInfo);

		if(IsTargetBeingEatenBySnake(Cody))
			SetTargetInvalid(CodyTargetInfo);

		if(ShouldEnterHypnosis(Owner))
			SetTargetInvalid(CodyTargetInfo);

		if(IsInHypnosis(Owner))
			SetTargetInvalid(CodyTargetInfo);

		if(!bIsTracingToCody && CodyTargetInfo.bVisionRange)
		{
			bIsTracingToCody = true;
			AsyncTrace.TraceSingle(GetTraceParams(May, EyesLocation, CodyLocation), this, n"MurderMicrophoneVisibility_Cody", FHazeAsyncTraceComponentCompleteDelegate(this, n"Handle_TraceComplete_Cody"));
		}

		if(!bIsTracingToMay && MayTargetInfo.bVisionRange)
		{

			bIsTracingToMay = true;
			AsyncTrace.TraceSingle(GetTraceParams(Cody, EyesLocation, MayLocation), this, n"MurderMicrophoneVisibility_May", FHazeAsyncTraceComponentCompleteDelegate(this, n"Handle_TraceComplete_May"));
		}
	}

	AHazePlayerCharacter GetClosestTarget() const property
	{
		int VisibleTargets = 0;

		if(CodyTargetInfo.bHasSight)
			VisibleTargets++;
		
		if(MayTargetInfo.bHasSight)
			VisibleTargets++;

		if(VisibleTargets > 1)
		{
			if(CodyTargetInfo.DistanceSq < MayTargetInfo.DistanceSq)
				return CodyTargetInfo.Player;
			else
				return MayTargetInfo.Player;
		}

		if(VisibleTargets == 1)
		{
			if(CodyTargetInfo.bHasSight)
				return CodyTargetInfo.Player;
			else if(MayTargetInfo.bHasSight)
				return MayTargetInfo.Player;
		}

		return nullptr;
	}

	private void SetTargetInvalid(FMurderMicrophoneTargetInfo& InTargetInfo)
	{
		InTargetInfo.bHasSight = false;
		InTargetInfo.bVisionRange = false;
		InTargetInfo.bChaseRange = false;
		InTargetInfo.bAggressiveRange = false;
	}

	private FHazeTraceParams GetTraceParams(AHazePlayerCharacter PlayerToIgnore, FVector EyesLocation, FVector To) const
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceParams.IgnoreActor(Owner);
		TraceParams.IgnoreActor(Owner, false);
		TraceParams.IgnoreActor(PlayerToIgnore, false);
		TraceParams.IgnoreActor(PlayerToIgnore);

		for(AActor AdditionalIgnore : _AdditionalIgnoreActors)
			TraceParams.IgnoreActor(AdditionalIgnore, false);

		TraceParams.SetToLineTrace();
		TraceParams.From = EyesLocation;
		TraceParams.To = To;
		return TraceParams;
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_TraceComplete_Cody(UObject Instigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		CodyTargetInfo.bHasSight = false;
		for(FHitResult Hit : Obstructions)
		{
			if(Hit.Actor == Game::GetCody())
			{
				CodyTargetInfo.bHasSight = true;
				break;
			}
		}

		bIsTracingToCody = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_TraceComplete_May(UObject Instigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		MayTargetInfo.bHasSight = false;

		for(FHitResult Hit : Obstructions)
		{
			if(Hit.Actor == Game::GetMay())
			{
				MayTargetInfo.bHasSight = true;
				break;
			}
		}

		bIsTracingToMay = false;
	}

	bool IsPointInsideChaseRange(FVector InPoint)
	{
		const FVector Origin = Owner.ActorLocation;
		return Origin.DistSquared(InPoint) < ChaseRangeSq;

	}

	bool HasSightToTarget(AHazePlayerCharacter InPlayer) const
	{
		if(InPlayer == nullptr)
			return false;

		if(InPlayer.IsMay())
			return MayTargetInfo.bHasSight;

		return CodyTargetInfo.bHasSight;
	}

	bool IsTargetValid(AHazePlayerCharacter InPlayer) const
	{
		if(InPlayer == nullptr)
			return false;

		if(InPlayer.IsMay())
			return MayTargetInfo.bHasSight && MayTargetInfo.bChaseRange && MayTargetInfo.bAggressiveRange && MayTargetInfo.bVisionRange;

		return CodyTargetInfo.bHasSight && CodyTargetInfo.bChaseRange && CodyTargetInfo.bAggressiveRange && CodyTargetInfo.bVisionRange;
	}

	bool IsTargetWithinAggressiveRange(AHazePlayerCharacter InPlayer) const
	{
		if(InPlayer == nullptr)
			return false;

		if(InPlayer.IsMay())
			return MayTargetInfo.bHasSight && MayTargetInfo.bAggressiveRange;

		return CodyTargetInfo.bHasSight && CodyTargetInfo.bAggressiveRange;
	}

	bool IsTargetWithinChaseRange(AHazePlayerCharacter InPlayer) const
	{
		if(InPlayer == nullptr)
			return false;

		if(InPlayer.IsMay())
			return MayTargetInfo.bHasSight && MayTargetInfo.bChaseRange;

		return CodyTargetInfo.bHasSight && CodyTargetInfo.bChaseRange;
	}

	bool IsTargetWithinVisionRange(AHazePlayerCharacter InPlayer) const
	{
		if(InPlayer == nullptr)
			return false;

		if(InPlayer.IsMay())
			return MayTargetInfo.bHasSight && MayTargetInfo.bVisionRange;

		return CodyTargetInfo.bHasSight && CodyTargetInfo.bVisionRange;
	}

#if TEST
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//PrintToScreen("May: Visible: " + MayTargetInfo.bVisible + " Chase: " + MayTargetInfo.bChaseRange + " Aggressive " + MayTargetInfo.bAggressiveRange + " Distance: " + FMath::Sqrt(MayTargetInfo.DistanceSq));
		//PrintToScreen("Cody: Visible: " + CodyTargetInfo.bVisible + " Chase: " + CodyTargetInfo.bChaseRange + " Aggressive " + CodyTargetInfo.bAggressiveRange + " Distance: " + FMath::Sqrt(CodyTargetInfo.DistanceSq));
	}
#endif // TEST

	void DebugDrawVision()
	{
		System::DrawDebugSphere(Owner.ActorLocation, AggressiveRange, 12, FLinearColor::Red, 0, 6);
		System::DrawDebugSphere(Owner.ActorLocation, ChaseRange, 12, FLinearColor::Blue, 0, 6);
		System::DrawDebugSphere(Owner.ActorLocation, VisionRange, 12, FLinearColor::Purple, 0, 6);
	}

	void SetIgnorePlayer(bool bValue)
	{
		if(!HasControl())
			return;

		NetSetIgnorePlayer(bValue);
	}

	bool IsTargetBeingEatenBySnake(AHazePlayerCharacter TargetPlayer)
	{

		UMurderMicrophonePlayerComponent MicroComp = UMurderMicrophonePlayerComponent::GetOrCreate(TargetPlayer);
		return MicroComp.bIsEatenBySnake;
	}

	void SetTargetEatenBySnake(AHazePlayerCharacter TargetPlayer, bool bValue)
	{
		UMurderMicrophonePlayerComponent MicroComp = UMurderMicrophonePlayerComponent::GetOrCreate(TargetPlayer);
		MicroComp.bIsEatenBySnake = bValue;
	}

	UFUNCTION(NetFunction)
	private void NetSetIgnorePlayer(bool bValue)
	{
		bIgnorePlayer = bValue;
	}

}
