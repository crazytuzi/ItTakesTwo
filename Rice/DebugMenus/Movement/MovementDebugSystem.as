import Vino.Movement.Components.MovementComponent;
import Peanuts.Movement.MovementDebugDataComponent;

enum EMovementCrumbDebugType
{
	Default,
	History,
}

class UMovementDebugSystem : UHazeDebugMenuScriptBase
{
	UPROPERTY()
	private UHazeMovementComponent MovementComponent = nullptr;
	
	UPROPERTY()
	private UHazeCrumbComponent CrumbComponent = nullptr;

	UPROPERTY()
	private UPrimitiveComponent CollisionComponent = nullptr;

	UPROPERTY()
	private AHazeActor DebugActor = nullptr;

	FVector LatestForceWithValue = FVector::ZeroVector;

	private EMovementCrumbDebugType CurrentCrumbDebugType = EMovementCrumbDebugType::Default;

	UFUNCTION()
	void SetActorToDebug(AHazeActor Actor)
	{
		DebugActor = nullptr;
		if(CrumbComponent != nullptr)
		{
			CrumbComponent.SetCrumbDebugActive(this, false);
		}

		if(Actor != nullptr)
		{
			DebugActor = Actor;
			MovementComponent = UHazeMovementComponent::Get(Actor);
			if(MovementComponent != nullptr)
			{
				OnComponentSelected(MovementComponent);
			}
				
			
			CrumbComponent = UHazeCrumbComponent::Get(Actor);

			if(CrumbComponent != nullptr)
			{
				CrumbComponent.SetCrumbDebugActive(this, true);
			}	

			AHazeCharacter Character = Cast<AHazeCharacter>(Actor);
			if(Character != nullptr)
				CollisionComponent = Character.CapsuleComponent;
			else
				CollisionComponent = UCapsuleComponent::Get(Actor);
		}
		else
		{
			MovementComponent = nullptr;
			CrumbComponent = nullptr;
			CollisionComponent = nullptr;
		}
	}


	UFUNCTION(BluePrintEvent)
	void OnComponentSelected(UHazeMovementComponent Component)
	{
	}

	UFUNCTION()
	void SetDrawDebugStatus(bool bStatus)
	{
		if (MovementComponent != nullptr)
			MovementComponent.bDrawDebug = bStatus;
	}

	UFUNCTION()
	void SetCrumbDebugType(EMovementCrumbDebugType Type)
	{
		CurrentCrumbDebugType = Type;
	}

	UFUNCTION(BlueprintPure)
	bool GetDrawDebugStatus()
	{
		if (MovementComponent != nullptr)
			return MovementComponent.bDrawDebug;
		return false;
	}

	UFUNCTION()
	FText UpdateDebugData()
	{
		FString DebugDataToBuild = "";
	
		if(DebugActor != nullptr)
		{			
			DebugDataToBuild += "\nOwner: " + DebugActor.GetName() 
			+ (DebugActor.HasControl() ? " (<Grey>Control</>)" : " (<Yellow>Remote</>)");

			
			float TimeDilation =  DebugActor.GetActorTimeDilation();
			FString TimeColor = TimeDilation > 1 ? "<Blue>" : TimeDilation < 1 ? "<Red>" : "";
			FString ColorEnd = TimeDilation != 1 ? "</>" : "";
			DebugDataToBuild += "\n" + TimeColor + "Time Dilation: " + TimeDilation + ColorEnd + "\n\n";

			DebugDataToBuild += "---- ACTOR CHARACTERISTICS ------------------" + "\n";
			DebugDataToBuild += "Location:             " + DebugActor.GetActorLocation().ToColorString() + "\n" ;
			DebugDataToBuild += "Rotation:             " +  DebugActor.GetActorRotation().ToColorString() + "\n" ;
			if (MovementComponent != nullptr)
			{
				DebugDataToBuild += "TargetRotation:  " + MovementComponent.GetTargetFacingRotation().Rotator().ToColorString() + "\n" ;
				DebugDataToBuild += "Rotation Speed:  " +  MovementComponent.GetTargetRotationSpeed() + "\n" ;
				DebugDataToBuild += "Step Amount:      " +  MovementComponent.GetStepAmount(-1) + "\n" ;
				DebugDataToBuild += "Walkable Angle:  " +  MovementComponent.GetWalkableAngle() + "\n" ;
			}
			
			const FMovementStateParams MovementState = DebugActor.GetMovementState();
			const FVector Velocity = MovementState.Velocity;
			const FVector ActualVelocity = DebugActor.GetActualVelocity();

			DebugDataToBuild += "<Green>Velocity:             </>" + DebugActor.GetActorRotation().UnrotateVector(Velocity).ToColorString() + " (" + TrimFloatValue(FMath::CeilToFloat(Velocity.Size()), true) + ")\n";
			DebugDataToBuild += "<Blue>ActualVelocity:  </>" + DebugActor.GetActorRotation().UnrotateVector(ActualVelocity).ToColorString() + " (" +  TrimFloatValue(FMath::CeilToFloat(ActualVelocity.Size()), true) + ")\n";
			DebugDataToBuild += "Horizontal Magnitude: " + Velocity.ConstrainToPlane(MovementState.WorldUp).Size() + "\n";

			const FVector VerticalVelocity = Velocity.ConstrainToDirection(MovementState.WorldUp);
			if(VerticalVelocity.Size() > 0)
			{
				if(VerticalVelocity.GetSafeNormal().DotProduct(MovementState.WorldUp) > 0.f)
				{
					DebugDataToBuild += "<Blue>Vertical Magnitude:      " + VerticalVelocity.Size() + "</>\n";
				}
				else
				{
					DebugDataToBuild += "<Red>Vertical Magnitude:     -" + VerticalVelocity.Size() + "</>\n";
				}
			}
			else
			{
				DebugDataToBuild += "Vertical Magnitude:      " + VerticalVelocity.Size() + "\n";	
			}
			DebugDataToBuild += "Total Magnitue:      " + Velocity.Size() + "\n";
			DebugDataToBuild += "Angular Velocity: " + DebugActor.GetActorRotation().UnrotateVector(MovementState.AngularVelocity).ToColorString() + "\n";		

			if(MovementComponent != nullptr)
			{
				DebugDataToBuild += "\n---- FORCES -----------------------------------" + "\n";
				UpdateAndBuildForces(DebugDataToBuild);
				DebugDataToBuild += "\n---- MOVEMENT COLLISION -------------" + "\n";

				if(CollisionComponent != nullptr)
				{
					DebugDataToBuild += "Profile: ";
					DebugDataToBuild += CollisionComponent.GetCollisionProfileName();
					DebugDataToBuild += "\n";
					DebugDataToBuild += "Radius: ";
					DebugDataToBuild += CollisionComponent.GetCollisionShape().GetCapsuleRadius();
					DebugDataToBuild += " | HalfHeight: ";
					DebugDataToBuild += CollisionComponent.GetCollisionShape().GetCapsuleHalfHeight();
					DebugDataToBuild += "\n";
				}

				UClass ControlType;
				UClass RemoteType;
				if(MovementComponent.GetCurrentCollisionSolverType(ControlType, RemoteType))
				{
					DebugDataToBuild += "CollisionHandler: ";
					if(MovementComponent.HasControl())
						DebugDataToBuild += ControlType.GetName();
					else
						DebugDataToBuild += RemoteType.GetName();
				}
				else
				{
					DebugDataToBuild += "No active collision handler";
				}	

				DebugDataToBuild += "\n";
				BuildGroundedData(DebugDataToBuild);
				DebugDataToBuild += "\n";
				BuildSquishedData(DebugDataToBuild);
				DebugDataToBuild += "\n";
				BuildImpactData(DebugDataToBuild, MovementComponent.PreviousImpacts.UpImpact, "UpImpact");
				BuildImpactData(DebugDataToBuild, MovementComponent.PreviousImpacts.ForwardImpact, "ForwardImpact");
				BuildImpactData(DebugDataToBuild, MovementComponent.PreviousImpacts.DownImpact, "DownImpact");

				BuildSolverDebugInformation(DebugDataToBuild);

				BuildPhysMaterials(DebugDataToBuild);
			}

			if (CrumbComponent != nullptr)
			{
				BuildRemoteData(DebugDataToBuild);
			}	
		}
		else
		{
			DebugDataToBuild += "No selected actor";
		}

		return FText::FromString(DebugDataToBuild);
	}

	void UpdateAndBuildForces(FString& StringToBuild)
	{
		FVector CurrentForce = MovementComponent.GetPreviousImpulse();
		if (!CurrentForce.IsNearlyZero())
			LatestForceWithValue = CurrentForce;

		StringToBuild += "Last applied force" + "\n";
		StringToBuild += "Force: " + LatestForceWithValue + "\n";
		StringToBuild += "Magnitude: " + LatestForceWithValue.Size() + "\n";
	}

	void BuildGroundedData(FString& StringToBuild)
	{
		StringToBuild += "\nAttached To: ";
		auto Attachment = DebugActor.GetAttachParentActor();
	
		if(Attachment != nullptr)
		{
			StringToBuild += "<Green>" + Attachment.GetName() + "</>";
			StringToBuild += " | Socket: " + DebugActor.GetAttachParentSocketName();
		}
		else
		{
			StringToBuild += "<Grey>Nothing</>";
		}

		StringToBuild += "\nMoveWithComponent To: ";
		UPrimitiveComponent Floor;
		FVector RelativeLocation;
		MovementComponent.GetCurrentMoveWithComponent(Floor, RelativeLocation);
		if(Floor != nullptr)
		{
			AActor Owner = Floor.GetOwner();
			if(Owner != nullptr)
				StringToBuild += "<Green>" + Floor.GetOwner().GetName() + "</>";
			else
				StringToBuild += "<Grey>Nothing</>";
		}
		else
			StringToBuild += "<Grey>Nothing</>";

		StringToBuild += "\n" + "Last frame platform delta: ";
		StringToBuild += MovementComponent.GetMoveWithLastDelta().ToColorString();

		FString GroundedColor = "<Green>";
		FString GroundedStateText = "Grounded";
		EHazeGroundedState GroundedState = MovementComponent.GetGroundedState();

		if (GroundedState == EHazeGroundedState::Airborne)
		{
			GroundedColor = "<Red>";
			GroundedStateText = "Airborne";
		}

		StringToBuild += "\n\nGrounded: " + GroundedColor + GroundedStateText + "</>";

	}

	void BuildSquishedData(FString& StringToBuild)
	{
		FString SquishedColor = "<Green>";

		if (MovementComponent.IsSquished())
			SquishedColor = "<Red>";

		StringToBuild += "Is Squished: " + SquishedColor + MovementComponent.IsSquished() + "</>";
	}

	void BuildSolverDebugInformation(FString& StringToBuild)
	{
		auto MoveDataDebugComp = UMovementDebugDataComponent::Get(MovementComponent.Owner);
		if (MoveDataDebugComp == nullptr)
			return;

		StringToBuild += "\n";
		StringToBuild += "Finalizer: ";
		if (MovementComponent.PreviousFinalizer == NAME_None)
			StringToBuild += "<Red>";
		else
			StringToBuild += "<Green>";
		StringToBuild += MovementComponent.PreviousFinalizer;
		StringToBuild += "</>";

		StringToBuild += "\n" + "DeltaProcessor: " + MovementComponent.ActiveDeltaProcessorName + "\n";


		StringToBuild += "\n" + "---IterationCounts---" + "\n";

		FString Color = "<Green>";

		int CurrentNumber = 1;
		for (int IterationCountCount : MoveDataDebugComp.IterationCounts)
		{
			if (CurrentNumber > 6)
				Color = "<Red>";
			else if (CurrentNumber > 3)
				Color = "<Yellow>";

			if (IterationCountCount > 0)
				StringToBuild += Color + CurrentNumber + ": </>" + IterationCountCount + "\n";

			++CurrentNumber;
		}

		StringToBuild += "\n" + "Depentrations: " + MoveDataDebugComp.DepentrationCounter + "\n";
	}

	void BuildImpactData(FString& StringToBuild, const FHitResult& Impact, FString ImpactType)
	{
		if (Impact.bBlockingHit && Impact.Component != nullptr)
		{
			FString HitName = Impact.Component.Name;
			if (Impact.Actor != nullptr)
			{
				HitName = "<Green>" + Impact.Actor.Name + "</> (" + HitName + ")"; 
			}

			StringToBuild += ImpactType + ": " + HitName  + "\n";
		}
		else
		{
			StringToBuild += ImpactType + "<Grey>: None</>" + "\n";
		}
	}

	void BuildRemoteData(FString& StringToBuild)
	{
		StringToBuild += "\n";
		StringToBuild += "---- SYNCING -----------------------------" + "\n";

		FHazeActorReplicationFinalized ReplicatedData;
		CrumbComponent.GetCurrentReplicatedData(ReplicatedData);
		USceneComponent RelativeFloor = ReplicatedData.GetLocationRelationComponent();
		StringToBuild += "\nCrumbLocation relative to: ";
		if(RelativeFloor != nullptr)
		{
			AActor Owner = RelativeFloor.GetOwner();
			if(Owner != nullptr)
				StringToBuild += "<Green>" + RelativeFloor.GetOwner().GetName() + "</>";
			else
				StringToBuild += "<Grey>Nothing</>";
		}
		else
		{
			StringToBuild += "<Grey>Nothing</>";
		}

		StringToBuild += "\n";

		CrumbComponent.GetDebugSyncInfo(StringToBuild);
		StringToBuild += "\n";

		if(CurrentCrumbDebugType == EMovementCrumbDebugType::Default && !DebugActor.HasControl())
		{
			bool bHasFoundInfo = false;
			StringToBuild += "---- CRUMBS (";
			StringToBuild += CrumbComponent.GetCrumbTrailLength();
			StringToBuild += ") -----------------------------\n";
			CrumbComponent.GetCrumbTrailDebugInfo(StringToBuild);
			StringToBuild += "\n";
		}
		else if(CurrentCrumbDebugType == EMovementCrumbDebugType::History || DebugActor.HasControl())
		{
			StringToBuild += "---- CRUMBS HISTORY ----------------------\n";
			CrumbComponent.GetDebugCrumbHistory(StringToBuild);
			StringToBuild += "\n";
		}
	}

	void BuildPhysMaterials(FString& StringToBuild)
	{
		StringToBuild += "\n-------------------------------------" + "\n";
		StringToBuild += "PhysMaterials:" + "\n" + "\n";

		StringToBuild += BuildPhysMaterial(MovementComponent.UpHit.PhysMaterial, "UpHit");
		StringToBuild += BuildPhysMaterial(MovementComponent.ForwardHit.PhysMaterial, "ForwardHit");
		StringToBuild += BuildPhysMaterial(MovementComponent.DownHit.PhysMaterial, "DownHit");
		StringToBuild += BuildPhysMaterial(MovementComponent.ContactSurfaceMaterial, "ContactSurface");
	}

	FString BuildPhysMaterial(UPhysicalMaterial Material, FString IDName)
	{
		if (Material == nullptr)
			return IDName + ": None" + "\n";

		return IDName + ": " + Material.GetName() + "\n";
	}
}
