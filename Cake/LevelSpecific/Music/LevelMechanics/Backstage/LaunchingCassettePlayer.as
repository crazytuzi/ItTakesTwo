import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FLaunchedPlayers();

class ALaunchingCassettePlayer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchRoot01;

	UPROPERTY(DefaultComponent, Attach = HatchRoot01)
	USceneComponent HatchMeshRoot01;

	UPROPERTY(DefaultComponent, Attach = HatchMeshRoot01)
	UStaticMeshComponent HatchMesh01;

	UPROPERTY(DefaultComponent, Attach = HatchRoot01)
	UBoxComponent HatchCollision01;

	UPROPERTY(DefaultComponent, Attach = HatchMeshRoot01)
	UBoxComponent HatchLeaveCollision01;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HatchRoot02;

	UPROPERTY(DefaultComponent, Attach = HatchRoot02)
	USceneComponent HatchMeshRoot02;

	UPROPERTY(DefaultComponent, Attach = HatchMeshRoot02)
	UStaticMeshComponent HatchMesh02;

	UPROPERTY(DefaultComponent, Attach = HatchRoot02)
	UBoxComponent HatchCollision02;

	UPROPERTY(DefaultComponent, Attach = HatchMeshRoot02)
	UBoxComponent HatchLeaveCollision02;
 
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EjectButtonRoot;

	UPROPERTY(DefaultComponent, Attach = EjectButtonRoot)
	UStaticMeshComponent EjectButtonMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCymbalImpactComponent CymbalImpactComp;
	default CymbalImpactComp.bCanBeTargeted = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ActivateDownImpactCheckCollision;

	UPROPERTY(DefaultComponent, Attach = HatchMesh01)
	UHazeAkComponent LeftHatchHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = HatchMesh02)
	UHazeAkComponent RightHatchHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchOnAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchOffAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchFullyClosedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CymbalHitAudioEvent;

	UPROPERTY()
	UMaterialInstance PressedButtonMat;

	UPROPERTY()
	UMaterialInstance UnPressedButtonMat;

	UPROPERTY()
	AActor ActorToLaunchMayTo;

	UPROPERTY()
	AActor ActorToLaunchCodyTo;

	UPROPERTY()
	FLaunchedPlayers CassettePlayerLaunchedPlayers;

	UPROPERTY()
	UCurveFloat HatchCurve;

	TArray<bool> HatchesClosed;
	default HatchesClosed.Add(false);
	default HatchesClosed.Add(false);

	float ButtonInterpSpeed = 15.f;

	bool bBothHatchesClosed = false;
	bool bHasSetWidgetVisible = false;

	FVector EjectButtonPushedLoc = FVector(-680.f, 0.f, 350.f);
	FVector EjectButtonNotPushedLoc = FVector(-634.f, 0.f, 388.f);

	FVector ButtonLitColor = FVector(10.f, 5.f, 0.f);
	FVector ButtonUnlitColor = FVector(0.f, 0.f, 0.f);

	float LeftHatchLerpValue = 0.f;
	float RightHatchLerpValue = 0.f;

	bool bTickLeftLerp = false;
	bool bTickRightLerp = false;

	bool bShouldCheckCodyDownImpact = false;
	bool bShouldCheckMayDownImpact = false;

	bool bCodyStandOnHatch01 = false;
	bool bCodyStandOnHatch02 = false;
	bool bMayStandOnHatch01 = false;
	bool bMayStandOnHatch02 = false;

	//used for audio
	bool bLeftHatchClosed = false;
	bool bRightHatchClosed = false;
	bool bLeftHatchFullyClosed = false;
	bool bRightHatchFullyClosed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");

		ActivateDownImpactCheckCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapImpactCheck");
		ActivateDownImpactCheckCollision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlapImpactCheck");

		// Because cody will be the one launching the players from a cymbal hit, let's make sure cody controls this object.
		SetControlSide(Game::GetCody());
	}

	UFUNCTION()
    void OnOverlapImpactCheck(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex,
	bool bFromSweep, const FHitResult&in Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetCody())
			bShouldCheckCodyDownImpact = true;
		else
			bShouldCheckMayDownImpact = true;
    }

	UFUNCTION()
    void OnEndOverlapImpactCheck(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (Player == Game::GetCody())
			bShouldCheckCodyDownImpact = false;
		else
			bShouldCheckMayDownImpact = false;	
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CheckForDownImpacts();

		if(!bLeftHatchFullyClosed && LeftHatchLerpValue == 1.0)
		{
			LeftHatchHazeAkComp.HazePostEvent(HatchFullyClosedAudioEvent);
			bLeftHatchFullyClosed = true;
		}
		else if(bLeftHatchFullyClosed && LeftHatchLerpValue != 1.0)
		{
			bLeftHatchFullyClosed = false;
		}

		if(!bRightHatchFullyClosed && RightHatchLerpValue == 1.0)
		{
			RightHatchHazeAkComp.HazePostEvent(HatchFullyClosedAudioEvent);
			bRightHatchFullyClosed = true;
		}
		else if(bRightHatchFullyClosed && RightHatchLerpValue != 1.0)
		{
			bRightHatchFullyClosed = false;
		}

		if (bCodyStandOnHatch01 || bMayStandOnHatch01)
		{
			LeftHatchLerpValue += DeltaTime * 2.f;
			LeftHatchLerpValue = FMath::Min(LeftHatchLerpValue, 1.f);
			if (LeftHatchLerpValue >= 1.f)
				HatchesClosed[0] = true;
			if(!bLeftHatchClosed)
			{
				LeftHatchHazeAkComp.HazePostEvent(HatchOnAudioEvent);
				bLeftHatchClosed = true;
			}
		} else
		{
			LeftHatchLerpValue -= DeltaTime * 2.f;
			LeftHatchLerpValue = FMath::Max(LeftHatchLerpValue, 0.f);
			if (LeftHatchLerpValue < 1.f)
				HatchesClosed[0] = false;
			if(bLeftHatchClosed)
			{
				LeftHatchHazeAkComp.HazePostEvent(HatchOffAudioEvent);
				bLeftHatchClosed = false;
			}
		}

		if (bCodyStandOnHatch02 || bMayStandOnHatch02)
		{
			RightHatchLerpValue += DeltaTime * 2.f;
			RightHatchLerpValue = FMath::Min(RightHatchLerpValue, 1.f);
			if (RightHatchLerpValue >= 1.f)
				HatchesClosed[1] = true;
			if(!bRightHatchClosed)
			{
				RightHatchHazeAkComp.HazePostEvent(HatchOnAudioEvent);
				bRightHatchClosed = true;
			}
		} else
		{
			RightHatchLerpValue -= DeltaTime * 2.f;
			RightHatchLerpValue = FMath::Max(RightHatchLerpValue, 0.f);
			if (RightHatchLerpValue < 1.f)
				HatchesClosed[1] = false;
			if(bRightHatchClosed)
			{
				RightHatchHazeAkComp.HazePostEvent(HatchOffAudioEvent);
				bRightHatchClosed = false;
			}
		}

		HatchMeshRoot01.SetRelativeRotation(FRotator(FMath::Lerp(0.f, -40.f, HatchCurve.GetFloatValue(LeftHatchLerpValue)), 0.f, 0.f));
		HatchMeshRoot02.SetRelativeRotation(FRotator(FMath::Lerp(0.f, -40.f, HatchCurve.GetFloatValue(RightHatchLerpValue)), 0.f, 0.f));

		bool bTempHatchesClosed = true;
		for (bool Hatch : HatchesClosed)
		{
			if (!Hatch)
				bTempHatchesClosed = false;
		}

		FVector TargetButtonLocation = bTempHatchesClosed ? EjectButtonNotPushedLoc : EjectButtonPushedLoc;
		FVector ColorToSet = bTempHatchesClosed ? ButtonLitColor : ButtonUnlitColor;
		bBothHatchesClosed = bTempHatchesClosed;
		EjectButtonRoot.SetRelativeLocation(FMath::VInterpTo(EjectButtonRoot.RelativeLocation, TargetButtonLocation, DeltaTime, ButtonInterpSpeed));
		EjectButtonMesh.SetVectorParameterValueOnMaterialIndex(0, n"Emissive Tint", ColorToSet);

		if(HasControl())
		{
			if (bBothHatchesClosed && !bHasSetWidgetVisible)
			{
				bHasSetWidgetVisible = true;
				NetSetWidgetVisible(true);
				FHazePointOfInterest Poi;
				Poi.Blend = 1.f;
				Poi.Duration = 1.f;
				Poi.FocusTarget.Component = CymbalImpactComp;
				Game::GetCody().ApplyPointOfInterest(Poi, this);
			}
			else if (!bBothHatchesClosed && bHasSetWidgetVisible)
			{
				bHasSetWidgetVisible = false;
				NetSetWidgetVisible(false);
				Game::GetCody().ClearPointOfInterestByInstigator(this);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetSetWidgetVisible(bool bVisible)
	{
		CymbalImpactComp.bCanBeTargeted = bVisible;
	}

	void CheckForDownImpacts()
	{
		if (bShouldCheckMayDownImpact)
		{
			UPrimitiveComponent HitComp = UHazeMovementComponent::Get(Game::GetMay()).GetDownHit().Component;
			if (bMayStandOnHatch01)
			{
				if (HatchLeaveCollision01.IsOverlappingActor(Game::GetMay()))
					bMayStandOnHatch01 = true;
				else
					bMayStandOnHatch01 = false;				
			}
			else if (bMayStandOnHatch02)
			{
				if (HatchLeaveCollision02.IsOverlappingActor(Game::GetMay()))
					bMayStandOnHatch02 = true;
				else
					bMayStandOnHatch02 = false;	
			}
			else if (HitComp == HatchMesh01)
			{
				bMayStandOnHatch01 = true;
				bMayStandOnHatch02 = false;
			} else if (HitComp == HatchMesh02)
			{
				bMayStandOnHatch02 = true;
				bMayStandOnHatch01 = false;
			} else 
			{
				bMayStandOnHatch01 = false;
				bMayStandOnHatch02 = false;
			}
		} else 
		{
			bMayStandOnHatch01 = false;
			bMayStandOnHatch02 = false;
		}

		if (bShouldCheckCodyDownImpact)
		{
			UPrimitiveComponent HitComp = UHazeMovementComponent::Get(Game::GetCody()).GetDownHit().Component;
			if (bCodyStandOnHatch01)
			{
				if (HatchLeaveCollision01.IsOverlappingActor(Game::GetCody()))
					bCodyStandOnHatch01 = true;
				else
					bCodyStandOnHatch01 = false;				
			}
			else if (bCodyStandOnHatch02)
			{
				if (HatchLeaveCollision02.IsOverlappingActor(Game::GetCody()))
					bCodyStandOnHatch02 = true;
				else
					bCodyStandOnHatch02 = false;	
			}
			else if (HitComp == HatchMesh01)
			{
				bCodyStandOnHatch01 = true;
				bCodyStandOnHatch02 = false;
			} else if (HitComp == HatchMesh02)
			{
				bCodyStandOnHatch02 = true;
				bCodyStandOnHatch01 = false;
			} else
			{
				bCodyStandOnHatch01 = false;
				bCodyStandOnHatch02 = false;
			}
		} else 
		{
			bCodyStandOnHatch01 = false;
			bCodyStandOnHatch02 = false;
		}
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if (!HasControl())
			return;

		if (!HitInfo.bAutoAimHit)
			return;			

		if (!bBothHatchesClosed)
			return;

		UHazeAkComponent::HazePostEventFireForget(CymbalHitAudioEvent, this.GetActorTransform());
		NetLaunchPlayers();
	}

	UFUNCTION(NetFunction)
	void NetLaunchPlayers()
	{
		for (auto Player : Game::Players)
			Player.TriggerMovementTransition(this);

		FHazeJumpToData MayJumpData;
		MayJumpData.Transform = ActorToLaunchMayTo.GetActorTransform();
		MayJumpData.AdditionalHeight = 2500.f;
		JumpTo::ActivateJumpTo(Game::GetMay(), MayJumpData);

		FHazeJumpToData CodyJumpData;
		CodyJumpData.Transform = ActorToLaunchCodyTo.GetActorTransform();
		CodyJumpData.AdditionalHeight = 2500.f;
		JumpTo::ActivateJumpTo(Game::GetCody(), CodyJumpData);

		CassettePlayerLaunchedPlayers.Broadcast();

		Game::GetCody().ClearPointOfInterestByInstigator(this);
	}
}