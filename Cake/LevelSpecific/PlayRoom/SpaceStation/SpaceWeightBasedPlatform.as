import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Peanuts.Audio.AudioStatics;

//audio rtpc to add:
//HazeAkComp.SetRTPCValue("Rtpc_SpaceStation_Platform_WeightPlatform_Velocity", ValueToSet);


UCLASS(Abstract)
class ASpaceWeightBasedPlatform : AHazeActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent LeftSpring;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent RightSpring;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UHazeInheritPlatformVelocityComponent InheritVelocityComp;
	default InheritVelocityComp.bInheritHorizontalVelocity = false;
	default InheritVelocityComp.bInheritVerticalVelocity = true;

	UPROPERTY(Category = "Audio Events", EditDefaultsOnly)
	UAkAudioEvent StartWeightPlatformAudioEvent;

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewAlpha = 0.f;

	float TotalWeight = 0.f;
	float CurrentOffset = 0.f;
	float PreviousOffset = 0.f;
	float MaxOffset = 1600.f;
	float CurrentAlpha = 0.f;
	float VelocityAlpha = 0.f;

	float UpInterpSpeed = 0.075f;
	float DownInterpSpeed = 0.25f;

	bool bMayOnBoard = false;
	bool bCodyOnBoard = false;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -1600.f;
	default PhysValue.UpperBound = 0.f;
	default PhysValue.LowerBounciness = 0.7f;
	default PhysValue.UpperBounciness = 0.7f;
	default PhysValue.Friction = 2.2f;

	float SpringSpeed = 2.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float CurOffset = FMath::Lerp(0.f, MaxOffset, PreviewAlpha);
		PlatformRoot.SetRelativeLocation(FVector(0.f, 0.f, -CurOffset));
		float CurSpringScale = FMath::Lerp(5.5f, 0.5f, PreviewAlpha);
		LeftSpring.SetRelativeScale3D(FVector(CurSpringScale, 5.f, 5.f));
		RightSpring.SetRelativeScale3D(FVector(CurSpringScale, 5.f, 5.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

		HazeAkComp.HazePostEvent(StartWeightPlatformAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Player == Game::GetMay())
			bMayOnBoard = true;
		else
			bCodyOnBoard = true;

		// PhysValue.AddImpulse(-50.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		if (Player == Game::GetMay())
			bMayOnBoard = false;
		else
			bCodyOnBoard = false;

		PhysValue.AddImpulse(-80.f);
		SpringSpeed = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float SpringTarget = 0.f;

		if (bCodyOnBoard)
		{
			UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Game::GetCody());
			if (ChangeSizeComp != nullptr)
			{
				if (ChangeSizeComp.CurrentSize == ECharacterSize::Large)
				{
					PhysValue.AddAcceleration(-3200.f);
					SpringTarget -= 950.f;
				}
				else if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
				{
					SpringTarget -= 50.f;
				}
				else
					SpringTarget -= 750.f;
			}
		}

		if (bMayOnBoard)
			SpringTarget -= 750.f;

		SpringSpeed = FMath::FInterpConstantTo(SpringSpeed, 4.f, DeltaTime, 0.75f);
		PhysValue.SpringTowards(SpringTarget, SpringSpeed);
		PhysValue.Update(DeltaTime);

		if (!FMath::IsNearlyEqual(PreviousOffset, PhysValue.Value, 0.025f))
		{
			PlatformRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));

			float OffsetAlpha = FMath::GetMappedRangeValueClamped(FVector2D(0.f, -1800.f), FVector2D(0.f, 1.f), PhysValue.Value);
			float CurSpringScale = FMath::Lerp(5.5f, 0.5f, OffsetAlpha);
			LeftSpring.SetRelativeScale3D(FVector(CurSpringScale, 5.f, 5.f));
			RightSpring.SetRelativeScale3D(FVector(CurSpringScale, 5.f, 5.f));
			PreviousOffset = CurrentOffset;
			CurrentOffset = PhysValue.Value;
		}
		else
			CurrentOffset = PreviousOffset;

		float VelocityDelta = PreviousOffset - CurrentOffset;
		float TargetVelocityAlpha = 0.f;
		if (VelocityDelta > 0.f)
			TargetVelocityAlpha = 1.f;
		else if (VelocityDelta < 0.f)
			TargetVelocityAlpha = -1.f;

		VelocityAlpha = FMath::FInterpTo(VelocityAlpha, TargetVelocityAlpha, DeltaTime, 10.f);

		if (StartWeightPlatformAudioEvent != nullptr)
		{
			HazeAkComp.SetRTPCValue("Rtpc_SpaceStation_Platform_WeightPlatform_Velocity", VelocityAlpha);
		}
	}
}