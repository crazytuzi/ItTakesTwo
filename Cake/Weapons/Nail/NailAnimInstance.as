import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailWeaponMeshComponent;
import Peanuts.Outlines.Outlines;
class UNailAnimInstanceFeatureBase : UHazeFeatureSubAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	UNailWeaponMeshComponent NailMesh;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Cody;

	UPROPERTY(BlueprintReadOnly)
	UNailWielderComponent NailWielderComp; 

	UPROPERTY(BlueprintReadOnly)
	FTransform RightAttachPos;

	UPROPERTY(BlueprintReadOnly)
	FTransform NailSocketPos;

	// Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{		
		if(OwningActor == nullptr)
			return;

		NailMesh = UNailWeaponMeshComponent::Get(OwningActor);

		Cody = Game::GetCody();

		if(Cody != nullptr)
			NailWielderComp = UNailWielderComponent::GetOrCreate(Cody);

		// if(bPrintDebug)
  	    // 	System::SetTimer(this, n"CreateDebugMeshOutline", 1.f, bLooping=false);
	}

	// Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(OwningActor == nullptr)
			return;

		if(NailMesh == nullptr)
			NailMesh = UNailWeaponMeshComponent::Get(OwningActor);

		if(Cody == nullptr)
			Cody = Game::GetCody();

		if(NailWielderComp == nullptr && Cody != nullptr)
			NailWielderComp = UNailWielderComponent::GetOrCreate(Cody);

		if(NailMesh == nullptr || Cody == nullptr || NailWielderComp == nullptr)
			return;

		bRecallingAllNails = GetAnimBoolParam(n"RecallingAllNails", true);
		bRecallingSingleNail = GetAnimBoolParam(n"RecallingSingleNail", true);

		AimRotationSpeed = GetAnimFloatParam(n"AimRotationSpeed", true);
		AimSpace_Pitch = GetAnimFloatParam(n"AimSpacePitch", true);
		AimSpace_Pitch = FMath::Clamp(AimSpace_Pitch, -45,45);

		bPierced= GetAnimBoolParam(n"NailPierced", true);
		bUnpierced = GetAnimBoolParam(n"NailUnpierced", true);
		bSubmerged = GetAnimBoolParam(n"NailSubmerged", false);
		bCollision = GetAnimBoolParam(n"NailCollision", true);
		bAim = GetAnimBoolParam(n"NailAiming", true);
		bEquip = GetAnimBoolParam(n"NailEquip", true);
		bUnequip = GetAnimBoolParam(n"NailUnequip", true);
		bEquippedToHand = GetAnimBoolParam(n"NailEquippedToHand", true);
		bThrow = GetAnimBoolParam(n"NailThrow", true);
		AssignedIndex = NailMesh.AssignedIndex;
		bCatch = GetAnimBoolParam(n"NailCatch", true);

		bIsEquippedToHand = NailWielderComp.NailEquippedToHand == OwningActor ? NailWielderComp.HasNailEquippedToHand() : false;
		bIsUnequipped = !NailWielderComp.IsNailEquipped(Cast<ANailWeaponActor>(OwningActor));

		RightAttachPos = Cody.Mesh.GetSocketTransform(n"RightAttach");
		NailSocketPos = Cody.Mesh.GetSocketTransform(n"NailSocket");
		bWiggling = NailWielderComp.IsWigglingOutOfPierce(OwningActor);


		if(bPrintDebug)
		{
			FLinearColor DesiredIdx = FLinearColor::White;

			if(AssignedIndex == 1)
				DesiredIdx = FLinearColor::Yellow;
			else if(AssignedIndex == 2)
				DesiredIdx = FLinearColor::Green;
			else if(AssignedIndex == 3)
				DesiredIdx = FLinearColor::LucBlue;

			PrintToScreen("NewAssigned Idx: " + AssignedIndex, 0.f, DesiredIdx);
		}
			
		BSInput = Cody.Mesh.GetAnimationUpdateParams().MovementVelocityBlendSpaceInput;
		Speed = Cody.Mesh.GetAnimationUpdateParams().Speed;		
		bCodyThrow = MovementName::IsFeatureTagEqualTo(Cody.Mesh.GetAnimationUpdateParams().LocomotionTag, n"NailThrow");
		bCodyCatch = MovementName::IsFeatureTagEqualTo(Cody.Mesh.GetAnimationUpdateParams().LocomotionTag, n"NailCatch");

		if(Speed < 3){
			bIsMoving = false;
		}
		else{
			bIsMoving = true;
		}	

	}

    UFUNCTION()
	void CreateDebugMeshOutline()
	{
		if(NailMesh == nullptr || Cody == nullptr)
			return;

		FOutline OutlineColor = FOutlines::May;
		if(NailMesh.AssignedIndex == 1)
			OutlineColor = FOutlines::Red;
		else if(NailMesh.AssignedIndex == 2)
			OutlineColor = FOutlines::Green;
		else if(NailMesh.AssignedIndex == 3)
			OutlineColor = FOutlines::Blue;

		CreateMeshOutline(NailMesh, OutlineColor);
	}

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bWiggling = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEquippedToHand = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsEquippedToHand = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsUnequipped = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int AssignedIndex = -1;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int PreviousAssigendIndex = -1;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEquip = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUnequip= false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCatch = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSubmerged = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCollision = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPierced = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUnpierced = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAim = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bThrow = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRecallingSingleNail = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRecallingAllNails = false;

	// float because the currently used AimSpace is only 1D //Sydney
	UPROPERTY(BlueprintReadOnly)
	float AimSpace_Pitch = 0.f;

	// How fast the player is rotating 
	UPROPERTY(BlueprintReadOnly)
	float AimRotationSpeed = 0.f;

	UPROPERTY(BlueprintReadOnly)
	FVector2D BSInput;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsMoving = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCodyThrow = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCodyCatch = false;

	float Speed = 0.f;

	UPROPERTY(BlueprintReadOnly)
	bool bPrintDebug = false;
}