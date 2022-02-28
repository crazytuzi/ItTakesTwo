import Rice.TemporalLog.TemporalLogComponent;
import Vino.Movement.Components.MovementComponent;

class UCrumbTemporalLogAction : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		auto CrumbComp = UHazeCrumbComponent::Get(Actor);
		if (CrumbComp == nullptr)
			return;

		UTemporalLogObject CrumbLog = Log.LogObject(n"Crumb", CrumbComp, bLogProperties = false);

		AHazeCharacter Character = Cast<AHazeCharacter>(Actor);
		FVector2D CollisionSize = FVector2D(50.f, 88.f);
		if(Character != nullptr)
		{
			FVector CharacterLocation = Character.GetActorCenterLocation();
			CollisionSize = Character.GetCollisionSize();
			CrumbLog.LogCapsule(n"CrumbTrail", CharacterLocation, CollisionSize.Y, CollisionSize.X);
		}

		// Setup all the crumb information for this frame
		const int MaxCrumbAmount = 3;
		FTemporalCrumbTrailData TemporalData;
		TemporalData.Initialize(CrumbComp, MaxCrumbAmount);

		CrumbLog.LogValue(n"ControlSide", TemporalData.bHasControl ? "ControlSide" : "RemoteSide");
		CrumbLog.LogValue(n"NetworkTag", TemporalData.CurrentNetworkTag);
		CrumbLog.LogValue(n"TrailLength", "" + FMath::RoundToInt(TemporalData.TrailLength));
		CrumbLog.LogValue(n"DeltaTime", TemporalData.DeltaTime);
		CrumbLog.LogValue(n"DeltaTimeModifier", TemporalData.DeltaTimeModifier);
		CrumbLog.LogValue(n"TimeStamp", TemporalData.ActorTimeStamp);

		if(TemporalData.bMovementSyncronisationIsBlocked)
			CrumbLog.LogValue(n"MovementSyncronisationIsBlocked", TemporalData.MovementSyncronisationIsBlockedInfo);

		if(TemporalData.bIsAwatingTransitionSyncs)
			CrumbLog.LogValue(n"MovementSyncronisationIsBlocked", TemporalData.AwatingTransitionSyncsInfo);

		FString LogType = "";
		bool bHasValue = false;

		if(TemporalData.ConsumedActorCrumbs.Num() > 0)
		{
			bHasValue = true;
			LogType += "CONSUMED";
		}

		if(TemporalData.bCurrentActorCrumbIsValid)
		{
			if(bHasValue)
				LogType += "_";

			bHasValue = true;
			LogType += "CURRENT";
		}

		if(TemporalData.ActorCrumbArray.Num() > 0)
		{
			if(bHasValue)
				LogType += "_";
			
			bHasValue = true;
			LogType += "TRAIL";
		}

		if(bHasValue)
			CrumbLog.LogValue(n"TemporalType", LogType);
		else
			CrumbLog.LogValue(n"TemporalType", "EMPTY");

		// Consumed
		for(int i = 0; i < TemporalData.ConsumedActorCrumbs.Num(); ++i)
		{
			LogActorCrumb(CrumbLog, TemporalData.ConsumedActorCrumbs[i], CollisionSize, i);
		}

		// Current
		if(TemporalData.bCurrentActorCrumbIsValid)
		{
			LogActorCrumb(CrumbLog, TemporalData.CurrentActorCrumb, CollisionSize);
		}
			
		// Trail
		for(int i = 0; i < TemporalData.ActorCrumbArray.Num(); ++i)
		{
			LogActorCrumb(CrumbLog, TemporalData.ActorCrumbArray[i], CollisionSize, i);
		}
	}

	void LogActorCrumb(UTemporalLogObject CrumbLog, const FTemporalActorCrumbData& Crumb, FVector2D CollisionSize, int Index = -1) const
	{
		FString TypePreFix = "";
		if(Crumb.TemporalType == ETemporalActorCrumbType::Trail)
		{	
			TypePreFix = "Trail_";
			TypePreFix += Index;
		}
		else if(Crumb.TemporalType == ETemporalActorCrumbType::Consumed)
		{
			TypePreFix = "Consumed_";
			TypePreFix += Index;
		}
		else
		{
			TypePreFix = "Current";
		}

		// Crumb Type
		CrumbLog.LogValue(FName(TypePreFix), Crumb.CrumbParams.CrumbType);
			
		// Times
		if(Crumb.TemporalType == ETemporalActorCrumbType::Current)
		{
			CrumbLog.LogValue(FName(TypePreFix + "_StartTimestamp"), Crumb.CrumbParams.StartTimeStamp);
			CrumbLog.LogValue(FName(TypePreFix + "_RemainingTime"), "" + Crumb.CrumbParams.RemaningTimeAmount + " / " + Crumb.CrumbParams.TotalTimeAmount);
			CrumbLog.LogValue(FName(TypePreFix + "_CrumbTimestamp"), Crumb.CrumbParams.TargetTimeStamp);
		}
		else
		{
			CrumbLog.LogValue(FName(TypePreFix + "_CrumbTimestamp"), Crumb.CrumbParams.TargetTimeStamp);
		}
		
		// Tag
		CrumbLog.LogValue(FName(TypePreFix + "_Tag"), Crumb.CrumbParams.CrumbTag);

		// Validation
		if(Crumb.TemporalType == ETemporalActorCrumbType::Consumed)
		{
			CrumbLog.LogValue(FName(TypePreFix + "_TimeWhenConsumed"), Crumb.CrumbParams.RemaingTimeWhenConsumed);
		}
		else
		{
			CrumbLog.LogValue(FName(TypePreFix + "_TimeWhenAdded"), Crumb.CrumbParams.TimeStampWhenAdded);
			CrumbLog.LogValue(FName(TypePreFix + "_InvalidFrames"), Crumb.CrumbParams.InvalidFrames);
		}

		// Actions
		if(Crumb.CrumbParams.CrumbName != NAME_None)
			CrumbLog.LogValue(FName(TypePreFix + "_" + Crumb.CrumbParams.CrumbName), Crumb.CrumbParams.CrumbName);
		
		if(Crumb.CrumbParams.ComparableCrumbType == EHazeCrumbType::Action)
			CrumbLog.LogValue(FName(TypePreFix + "_ActionType"), Crumb.CrumbParams.ActionType);

		if(Crumb.TemporalType != ETemporalActorCrumbType::Consumed)
			CrumbLog.LogValue(FName(TypePreFix + "_Status"), Crumb.CrumbParams.Status);

		// Graphics
		if(Crumb.TemporalType == ETemporalActorCrumbType::Current)
		{
		 	CrumbLog.LogLine(FName(TypePreFix + "_Translation"), Crumb.StartActorParams.Location, Crumb.TargetActorParams.Location, FLinearColor::White);
		 	CrumbLog.LogPoint(FName(TypePreFix + "_Crumb"), Crumb.TargetActorParams.Location, FLinearColor::Green);
			CrumbLog.LogCircle(FName(TypePreFix + "_Position"), Crumb.CurrentActorParams.Location, CollisionSize.X, Color = FLinearColor::Green);
		}
		else if(Crumb.TemporalType == ETemporalActorCrumbType::Trail)
		{
		 	CrumbLog.LogPoint(FName(TypePreFix + "_Crumb"), Crumb.TargetActorParams.Location, FLinearColor::White);
		}
		else if(Crumb.TemporalType == ETemporalActorCrumbType::Consumed)
		{
		 	CrumbLog.LogPoint(FName(TypePreFix + "_Crumb"), Crumb.TargetActorParams.Location, FLinearColor::Gray);
		}
	}
};
