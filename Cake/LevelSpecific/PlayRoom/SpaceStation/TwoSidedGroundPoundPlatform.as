import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FTwoSidedGroundPoundPlatformEvent();

UCLASS(Abstract)
class ATwoSidedGroundPoundPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent TopPlatform;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent BottomPlatform;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePlatformTimeLike;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwayAudioEvent;

	UPROPERTY()
	FTwoSidedGroundPoundPlatformEvent OnGroundPounded;

	UPROPERTY()
	bool bAtTop = true;

	UPROPERTY()
	FVector TopLocation = FVector(0.f, 0.f, 150.f);

	UPROPERTY()
	FVector BottomLocation = FVector(0.f, 0.f, -150.f);

	UPROPERTY()
	float SignTopOffset = 0.f;

	UPROPERTY()
	float SignBottomOffset = 0.f;

	UPROPERTY()
	int NumberOfMeshes = 1;

	UPROPERTY()
	bool bExtraPlatform = false;

	float SignStartRot = 0.f;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.bHasLowerBound = false;
	default PhysValue.bHasUpperBound = false;
	default PhysValue.LowerBounciness = 0.2f;
	default PhysValue.UpperBounciness = 0.2f;
	default PhysValue.Friction = 4.5f;

	float PhysTargetValue;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

		if (bAtTop)
		{
			PlatformRoot.SetRelativeLocation(TopLocation);
		}
		else
		{
			PlatformRoot.SetRelativeLocation(BottomLocation);
		}

		UStaticMesh MeshToUse = PlatformMesh.StaticMesh;
		if (MeshToUse == nullptr)
			return;

		for (int Index = 0, Count = NumberOfMeshes - 1; Index < Count; ++Index)
		{
			UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this);
			MeshComp.SetStaticMesh(MeshToUse);
			MeshComp.AttachToComponent(PlatformRoot);
			MeshComp.SetRelativeLocation(FVector(0.f, 0.f, PlatformMesh.RelativeLocation.Z - 320 * (Index + 1)));
		}

		if (bExtraPlatform)
		{
			UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this);
			MeshComp.SetStaticMesh(TopPlatform.StaticMesh);
			MeshComp.AttachToComponent(PlatformRoot);
			MeshComp.SetRelativeLocation(FVector(0.f, 0.f, 600.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PhysValue.SnapTo(PlatformRoot.RelativeLocation.Z, true);
		PhysTargetValue = PhysValue.Value;

		float Distance = (TopLocation - BottomLocation).Size();
		float PlayRate = 1/(Distance/500.f);
		MovePlatformTimeLike.SetPlayRate(PlayRate);

		MovePlatformTimeLike.BindUpdate(this, n"UpdateMovePlatform");
		MovePlatformTimeLike.BindFinished(this, n"FinishMovePlatform");

		FActorGroundPoundedDelegate GroundPoundDelegate;
		GroundPoundDelegate.BindUFunction(this, n"GroundPounded");
		BindOnActorGroundPounded(this, GroundPoundDelegate);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (MovePlatformTimeLike.IsPlaying())
			return;

		if (Player.IsMay() && (bAtTop || bExtraPlatform))
			return;

		if (Player.IsCody() && !bAtTop)
			return;

		if (Player.IsMay())
		{
			PhysValue.AddImpulse(120.f);
			HazeAkComp.HazePostEvent(SwayAudioEvent);
		}
			
		else
		{
			PhysValue.AddImpulse(-120.f);
			HazeAkComp.HazePostEvent(SwayAudioEvent);
		}
			
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION(NotBlueprintCallable)
	void GroundPounded(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
		{
			if (bAtTop)
				return;
		}
		else
		{
			if (!bAtTop)
				return;

			UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
			if (ChangeSizeComp != nullptr)
			{
				if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
					return;
			}
		}

		HazeAkComp.HazePostEvent(StartAudioEvent);
		MovePlatformTimeLike.PlayFromStart();
		OnGroundPounded.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePlatform(float CurValue)
	{
		FVector StartLoc = bAtTop ? TopLocation : BottomLocation;
		FVector EndLoc = bAtTop ? BottomLocation : TopLocation;
		FVector CurLoc = FMath::Lerp(StartLoc, EndLoc, CurValue);
		PlatformRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMovePlatform()
	{
		bAtTop = !bAtTop;
		HazeAkComp.HazePostEvent(StopAudioEvent);
		PhysValue.SnapTo(PlatformRoot.RelativeLocation.Z, true);
		PhysTargetValue = PhysValue.Value;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (MovePlatformTimeLike.IsPlaying())
			return;

		PhysValue.SpringTowards(PhysTargetValue, 55.f);
		PhysValue.Update(DeltaTime);

		PlatformRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
	}
}