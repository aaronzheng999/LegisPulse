import React from "react";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Globe, Clock, CheckCircle } from "lucide-react";

export default function AutoSyncIndicator({ lastSyncTime }) {
  return (
    <Card className="border-blue-200 bg-gradient-to-r from-blue-50 to-indigo-50">
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Globe className="w-5 h-5 text-blue-600" />
            </div>
            <div>
              <h4 className="font-semibold text-blue-900 text-sm">
                Auto-Sync from Georgia Legislature
              </h4>
              <p className="text-xs text-blue-700 mt-0.5">
                Bills are synced daily from legis.ga.gov
              </p>
            </div>
          </div>
          <div className="flex flex-col items-end gap-1">
            <Badge className="bg-green-500 text-white gap-1">
              <CheckCircle className="w-3 h-3" />
              Active
            </Badge>
            {lastSyncTime && (
              <span className="text-xs text-blue-600 flex items-center gap-1">
                <Clock className="w-3 h-3" />
                Last sync: {lastSyncTime}
              </span>
            )}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}